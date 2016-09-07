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

  def status
    # fetch valid clusters
    url = uri_to(
      site_clusters_path(params[:id]),
      :out
    )
    http = EM::HttpRequest.new(url).get(
      :query   => {'branch' => params[:branch] || 'master'},
      :timeout => 20,
      :head    => {'Accept' => media_type(:json)}
    )
    continue_if!(http, :is => [200])
    valid_clusters = JSON.parse(http.response)['items'].map{|i| i['uid']}
    Rails.logger.info "Valid clusters=#{valid_clusters.inspect}"

    result = {
      "uid" => Time.now.to_i,
      "nodes" => OAR::Resource.status(:clusters => valid_clusters),
      "links" => [
        {
          "rel" => "self",
          "href" => uri_to(status_site_path(params[:id])),
          "type" => media_type(:g5kitemjson)
        },
        {
          "rel" => "parent",
          "href" => uri_to(site_path(params[:id])),
          "type" => media_type(:g5kitemjson)
        }
      ]
    }
    respond_to do |format|
      format.g5kitemjson { render :json => result }
      format.json { render :json => result }
    end
  end
  
  protected
  
  def collection_path
    sites_path
  end
  
  def links_for_item(item)
    links = super(item)
    %w{jobs vlans metrics}.each do |rel| # abasu bug #7179 removed deployments
      links.push({
        "rel" => rel,
        "type" => media_type(:g5kcollectionjson),
        "href" => uri_to(File.join(resource_path(item["uid"]), rel))
      })
    end
    links.push({
      "rel" => "status",
      "type" => media_type(:g5kitemjson),
      "href" => uri_to(File.join(resource_path(item["uid"]), "status"))
    })
    links
  end

end
