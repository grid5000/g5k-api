# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ResourcesController < ApplicationController
  include Swagger::Blocks

  MAX_AGE = 60.seconds

  ['cluster', 'server', 'pdu', 'network_equipment'].each do |resource|
    resource_id = (resource + '_id').camelize(:lower)
    resources = resource.pluralize

    swagger_path "/sites/{siteId}/#{resources}" do
      operation :get do
        key :summary, "List #{resources}"
        key :description, "Fetch a collection of Grid'5000 #{resources} for a specific site."
        key :tags, ['reference-api']

        [:siteId, :deep, :branch, :date, :timestamp, :version].each do |param|
          parameter do
            key :$ref, param
          end
        end

        response 200 do
          key :description, "Grid'5000 #{resources} collection."
          content :'application/json'
        end
      end
    end

    swagger_path "/sites/{siteId}/#{resources}/{#{resource_id}}" do
      operation :get do
        key :summary, "Get #{resource} description"
        key :description, "Fetch the description of a specific #{resource}."
        key :tags, ['reference-api']

        parameter do
          key :$ref, resource_id.to_sym
        end

        [:siteId, :deep, :branch, :date, :timestamp, :version].each do |param|
          parameter do
            key :$ref, param
          end
        end

        response 200 do
          key :description, "The Grid'5000 #{resource} item."
          content :'application/json'
        end

        response 404 do
          key :description, "Grid'5000 #{resource} not found."
          content :'text/plain'
        end
      end
    end
  end

  # Return a collection of resources
  def index
    fetch(collection_path)
  end

  def show
    fetch(resource_path(params[:id]))
  end

  protected

  def fetch(path)
    allow :get; vary_on :accept
    Rails.logger.info "Fetching #{path}"

    enrich_params(params)

    object = lookup_path(path, params)

    raise NotFound, "Cannot find resource #{path}" if object.nil?

    if params[:deep]
      object['links'] = links_for_collection
    else
      if object.has_key?('items')
        object['links'] = links_for_collection
        object['items'].each do |item|
          item['links'] = links_for_item(item)
        end
      else
        object['links'] = links_for_item(object)
      end
    end

    object['version'] = repository.commit.oid

    last_modified [repository.commit.time, File.mtime(__FILE__)].max

    # If client asked for a specific version, it won't change anytime soon
    if params[:version] && params[:version] == object['version']
      expires_in(
        24 * 3600 * 30,
        public: true
      )
    else
      expires_in(
        MAX_AGE,
        :public => true,
        'must-revalidate' => true,
        'proxy-revalidate' => true,
        's-maxage' => MAX_AGE
      )
    end
    etag object.hash

    respond_to do |format|
      if object.has_key?('items')
        format.g5kcollectionjson { render json: object }
      else
        format.g5kitemjson { render json: object }
      end
      format.json { render json: object }
    end
  end

  def enrich_params(params)
    branch = params[:branch] || 'master'
    branch = ['origin', branch].join('/') unless Rails.env == 'test'
    params[:branch] = branch

    params[:queues] = if params[:queues].nil?
                        %w[admin default]
                      else
                        if params[:queues] == 'all'
                          %w[admin default production]
                        else
                          params[:queues].split(',')
                        end
                      end

    if params[:controller] == 'sites' && params[:action] == 'show' && params[:deep] && params[:job_id]
      params[:timestamp] = OAR::Job.expanded.find(params[:job_id]).start_time
    end
  end

  def lookup_path(path, params)
    object = repository.find(
      path.gsub(%r{/?platforms}, ''),
      branch: params[:branch],
      version: params[:version],
      timestamp: params[:timestamp],
      date: params[:date],
      deep: params[:deep]
    )

    raise ServerUnavailable if object.is_a?(Exception)
    return nil unless object

    # case logic for treating different scenarios
    case [params[:controller], params[:action]]

    # 1. case of a single cluster
    when %w[clusters show]
      # Add ["admin","default"] to 'queues' if nothing defined for that cluster
      object['queues'] = %w[admin default] if object['queues'].nil?
      object = nil if (object['queues'] & params[:queues]).empty?

    # 2. case of an array of clusters
    when %w[clusters index]
      unless params[:deep]
        # First, add ["admin","default"] to 'queues' if nothing defined for that cluster
        object['items'].each { |cluster| cluster['queues'] = %w[admin default] if cluster['queues'].nil? }
        # Then, filter out 'queues' that are not requested in params
        object['items'].delete_if { |cluster| (cluster['queues'] & params[:queues]).empty? }
        #          # This last step: to maintain current behaviour showing no 'queues' if not defined
        #          # Should be removed when 'queues' in all clusters are explicitly defined.
        #          object['items'].each { |cluster| cluster.delete_if { |key, value| key == 'queues' && value == ["default"] } }
        # Finally, set new 'total' to clusters shortlisted
        object['total'] = object['items'].length
      end

    when %w[sites show]
      if params[:deep] && params[:job_id]
        assigned_nodes = OAR::Job.expanded.find(
          params[:job_id]
        ).assigned_nodes

        clusters = {}
        assigned_nodes.each do |n|
          clusters[n.gsub(/([a-z]+)-[0-9]+.*/, '\1')] ||= []
          clusters[n.gsub(/([a-z]+)-[0-9]+.*/, '\1')] << n.gsub(/([a-z]+-[0-9]+).*/, '\1')
        end

        object['items'].delete_if { |key| !%w[clusters type uid].include?(key) }
        object['items']['clusters'].delete_if { |key, _| !clusters.keys.include?(key) }
        clusters.each do |cluster, nodes|
          if object['items']['clusters'][cluster]
            object['items']['clusters'][cluster]['nodes'].delete_if { |key| !nodes.include?(key['uid']) }
          end
        end

        object['total'] = object['items'].length
      end
    end

    object
  end

  # Must be overwritten by descendants
  def collection_path
    raise NotImplemented
  end

  def resource_path(id)
    File.join(collection_path, id)
  end

  def parent_path
    collection_path.gsub(%r{/[^/]+$}, '')
  end

  # Should be overwritten
  def links_for_item(item)
    links = []

    (item.delete('subresources') || []).each do |subresource|
      href = uri_to(resource_path(item['uid']) + '/' + subresource[:name])
      links.push({
        'rel' => subresource[:name],
        'href' => href,
        'type' => api_media_type(:g5kcollectionjson)
      })
    end

    links.push({
      'rel' => 'self',
      'type' => api_media_type(:g5kitemjson),
      'href' => uri_to(resource_path(item['uid']))
    })
    links.push({
      'rel' => 'parent',
      'type' => api_media_type(:g5kitemjson),
      'href' => uri_to(parent_path)
    })
    links.push({
      'rel' => 'version',
      'type' => api_media_type(:g5kitemjson),
      'href' => uri_to(File.join(resource_path(item['uid']), 'versions', item['version']))
    })
    links.push({
      'rel' => 'versions',
      'type' => api_media_type(:g5kcollectionjson),
      'href' => uri_to(File.join(resource_path(item['uid']), 'versions'))
    })
    links
  end

  # Should be overwritten
  def links_for_collection
    links = []
    links.push({
      'rel' => 'self',
      'type' => api_media_type(:g5kcollectionjson),
      'href' => uri_to(collection_path)
    })
    links.push({
      'rel' => 'parent',
      'type' => api_media_type(:g5kitemjson),
      'href' => uri_to(parent_path)
    })
    links
  end
end
