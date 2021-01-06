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

require 'resources_controller'

class SitesController < ResourcesController
  include Swagger::Blocks

  swagger_path '/sites' do
    operation :get do
      key :summary, 'List sites'
      key :description, "Fetch a collection of Grid'5000 sites."
      key :tags, ['reference-api']

      [:deep, :branch, :date, :timestamp, :version].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Grid'5000 sites collection."
        content api_media_type(:g5kcollectionjson)
      end
    end
  end

  swagger_path '/sites/{siteId}' do
    operation :get do
      key :summary, 'Get site description'
      key :description, 'Fetch the description of a specific site.'
      key :tags, ['reference-api']

      [:siteId, :deep, :branch, :date, :timestamp, :version].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "The Grid'5000 site item."
        content api_media_type(:g5kitemjson)
      end

      response 404 do
        key :description, "Grid'5000 site not found."
        content :'text/plain'
      end
    end
  end

  swagger_path '/sites/{siteId}/status' do
    operation :get do
      key :summary, 'Get site status'
      key :description, 'Fetch site OAR resources status and reservations.'
      key :tags, ['status']

      [:siteId, :statusDisks, :statusNodes, :statusVlans, :statusSubnets].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Grid'5000 site's OAR resources status."
        content api_media_type(:g5kitemjson) do
          schema do
            key :'$ref', :SiteStatus
          end
        end
      end
    end
  end

  def status
    # fetch valid clusters
    enrich_params(params)

    params[:job_details] = 'no' if is_anonymous?
    params[:waiting] = 'no' if is_anonymous?

    if params[:network_address]
      # optimization: when a network_address is specified, we can restrict the cluster to the one of the node
      # this avoids fetching the list of clusters, which is costly
      valid_clusters = [params[:network_address].split('-').first]
    else
      site_clusters = lookup_path("/sites/#{params[:id]}/clusters", params)
      valid_clusters = site_clusters['items'].map { |i| i['uid'] }
      Rails.logger.info "Valid clusters=#{valid_clusters.inspect}"
    end

    result = {
      'uid' => Time.now.to_i,
      'links' => [
        {
          'rel' => 'self',
          'href' => uri_to(status_site_path(params[:id])),
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => uri_to(site_path(params[:id])),
          'type' => api_media_type(:g5kitemjson)
        }
      ]
    }

    # Select the possible resources type from database. In disk case, even if
    # it doesn't exists we want it in the result (as an empty Hash value).
    rtypes = OAR::Resource.select(:type).distinct.map{ |t| t.type }
    rtypes.push('disk') unless rtypes.include?('disk')
    expected_rtypes = []

    rtypes.each do |oar_type|
      plural_type = OAR::Resource.api_type(oar_type)

      if params[plural_type] != 'no'
        expected_rtypes.push(oar_type)
      end
    end

    result.merge!(OAR::Resource.status(clusters: valid_clusters, network_address: params[:network_address], job_details: params[:job_details], waiting: params[:waiting], types: expected_rtypes))

    render_result(result)
  end

  protected

  def collection_path
    sites_path
  end

  def links_for_item(item)
    links = super(item)
    %w[jobs deployments vlans metrics storage].each do |rel|
      links.push({
        'rel' => rel,
        'type' => api_media_type(:g5kcollectionjson),
        'href' => uri_to(File.join(resource_path(item['uid']), rel))
      })
    end
    links.push({
      'rel' => 'status',
      'type' => api_media_type(:g5kitemjson),
      'href' => uri_to(File.join(resource_path(item['uid']), 'status'))
    })
    links
  end
end
