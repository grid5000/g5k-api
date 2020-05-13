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

class VersionsController < ApplicationController
  MAX_AGE = 60.seconds
  
  
  def index
    vary_on :accept; allow :get
    versions = repository.versions_for(
      resource_path, 
      :branch => params[:branch], 
      :offset => params[:offset], 
      :limit => params[:limit]
    )
    
    raise NotFound, "#{resource_path} does not exist." if versions["total"] == 0
    
    versions["items"].map!{|commit|
      metadata_for_commit(commit, resource_path)
    }
    versions["links"] = [
      {
        "rel" => "self", 
        "href" => uri_to("#{resource_path}/versions"), 
        "type" => api_media_type(:g5kcollectionjson)
      },
      {
        "rel" => "parent", 
        "href" => uri_to("#{resource_path.split("/")[0..-2].join("/")}"), 
        "type" => api_media_type(:g5kitemjson)
      }
    ]
    
    etag versions.hash
    expires_in MAX_AGE, :public => true
    
    respond_to do |format|
      format.g5kcollectionjson { render :json => versions }
      format.json { render :json => versions }
    end
  end
  
  def show
    vary_on :accept; allow :get
    version = params[:id]
    
    versions = repository.versions_for(
      resource_path, 
      :branch => version, 
      :offset => 0, 
      :limit => 1
    )
    raise NotFound, "The requested version '#{version}' does not exist or the resource '#{resource_path}' does not exist." if versions["total"] == 0
    # etag compute_etag(commit.id, resource_uri, response['Content-Type'], options.release_hash)
    
    output = metadata_for_commit(versions["items"][0], resource_path)

    etag versions.hash
    expires_in MAX_AGE, :public => true
    
    respond_to do |format|
      format.g5kitemjson { render :json => output }
      format.json { render :json => output }
    end
  end
  
  protected
  def resource_path
    @resource_path ||= params[:resource].gsub(/\/?platforms/, '')
  end
  
  def metadata_for_commit(commit, resource_path)
    { 
      'uid' => commit.id,
      'date' => commit.committed_date.httpdate,
      'message' => commit.message,
      'author' => commit.author.name,
      'type' => 'version',
      'links' => [
        {
          "rel" => "self", 
          "href" => uri_to("#{resource_path}/versions/#{commit.id}"), 
          "type" => api_media_type(:g5kitemjson)
        },
        {
          "rel" => "parent", 
          "href" => uri_to(resource_path), 
          "type" => api_media_type(:g5kitemjson)
        }
      ] 
    }
  end
end
