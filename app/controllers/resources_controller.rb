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

  MAX_AGE = 60.seconds

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
    branch = params[:branch] || 'master'
    branch = ['origin', branch].join("/") unless Rails.env == "test"

    # abasu : Added code for getting 'queues' element in hash params - 11.12.2015
    # abasu : In request to feature bug ref. #6363
    # abasu : params_queues is the array with 'queues' values passed in 'params'
    if params[:queues].nil? # no filter, so assign everything except "production"
       params[:queues] = ["admin","default"] 
    # As of 11.12.2015 the queues accepted are:
    # "all" or any combination of "admin", "default", "production"
    else 
       if params[:queues] == "all" # for use by sys-admin
          params[:queues] = ["admin","default","production"]
       else
          params[:queues] = params[:queues].split(",")
       end # if params[:queues] == "all"
    end # if params[:queues].nil?

    object=lookup_path(path,branch,params)
    
    
    raise NotFound, "Cannot find resource #{path}" if object.nil?
    if object.has_key?('items')
      object['links'] = links_for_collection(object)
      object['items'].each{|item|
        item['links'] = links_for_item(item)
      }
    else
      object['links'] = links_for_item(object)
    end

    object["version"] = repository.commit.id

    last_modified [repository.commit.committed_date, File.mtime(__FILE__)].max

    # If client asked for a specific version, it won't change anytime soon
    if params[:version] && params[:version] == object["version"]
      expires_in(
        24*3600*30,
        :public => true
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
        format.g5kcollectionjson { render :json => object }
      else
        format.g5kitemjson { render :json => object }
      end
      format.json { render :json => object }
    end
  end

  def lookup_path(path, branch, params)
    object = EM::Synchrony.sync repository.async_find(
      path.gsub(/\/?platforms/,''),
      :branch => branch,
      :version => params[:version]
    )
    
    # abasu : case logic for treating different scenarios - 11.12.2015
    case [params[:controller], params[:action]]
        
    # 1. case of a single cluster
    when ["clusters", "show"] 
      # Add ["admin","default"] to 'queues' if nothing defined for that cluster
      object['queues'] = ["admin","default"] if object['queues'].nil?
      object = nil if (object['queues'] & params[:queues]).empty?
      
    # 2. case of an array of clusters
    when ["clusters", "index"] 
      # First, add ["admin","default"] to 'queues' if nothing defined for that cluster
      object['items'].each { |cluster| cluster['queues'] = ["admin","default"] if cluster['queues'].nil? }
      # Then, filter out 'queues' that are not requested in params
      object['items'].delete_if { |cluster| (cluster['queues'] & params[:queues]).empty? }
=begin
         # This last step: to maintain current behaviour showing no 'queues' if not defined
         # Should be removed when 'queues' in all clusters are explicitly defined.
         object['items'].each { |cluster| cluster.delete_if { |key, value| key == 'queues' && value == ["default"] } }
=end
      # Finally, set new 'total' to clusters shortlisted
      object['total'] = object['items'].length
      
    end # case [params[:controller], params[:action]]
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
    collection_path.gsub(/\/[^\/]+$/, "")
  end

  # Should be overwritten
  def links_for_item(item)
    links = []

    (item.delete('subresources') || []).each do |subresource|
      href = uri_to(resource_path(item["uid"]) + "/" + subresource.name)
      links.push({
        "rel" => subresource.name, 
        "href" => href, 
        "type" => media_type(:g5kcollectionjson)
      })
    end

    links.push({
      "rel" => "self",
      "type" => media_type(:g5kitemjson),
      "href" => uri_to(resource_path(item["uid"]))
    })
    links.push({
      "rel" => "parent",
      "type" => media_type(:g5kitemjson),
      "href" => uri_to(parent_path)
    })
    links.push({
      "rel" => "version",
      "type" => media_type(:g5kitemjson),
      "href" => uri_to(File.join(resource_path(item["uid"]), "versions", item["version"]))
    })
    links.push({
      "rel" => "versions",
      "type" => media_type(:g5kcollectionjson),
      "href" => uri_to(File.join(resource_path(item["uid"]), "versions"))
    })
    links
  end

  # Should be overwritten
  def links_for_collection(collection)
    links = []
    links.push({
      "rel" => "self",
      "type" => media_type(:g5kcollectionjson),
      "href" => uri_to(collection_path)
    })
    links.push({
      "rel" => "parent",
      "type" => media_type(:g5kitemjson),
      "href" => uri_to(parent_path)
    }) unless parent_path.blank?
    links
  end

end
