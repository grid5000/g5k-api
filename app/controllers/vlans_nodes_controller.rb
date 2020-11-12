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

class VlansNodesController < ApplicationController
  include Vlans

  # Display nodes for a vlan
  def index
    allow :get
    expires_in 60.seconds

    nodes = @kavlan.nodes_vlan(params[:vlan_id])
    result = {
      'total' => nodes.length,
      'offset' => 0,
      'items' => nodes.map { |n| { 'uid' => n, 'vlan' => params[:vlan_id] } },
      'links' => links_for_collection
    }

    result['items'].each do |item|
      item['links'] = links_for_item(item)
    end

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  # Add nodes inside a vlan
  def add
    ensure_authenticated!
    allow :post

    unless request.content_type == "application/json"
      raise UnsupportedMediaType, "Content-Type #{request.content_type} not supported"
    end

    if params[:vlans_node][:_json].blank? || !params[:vlans_node][:_json].is_a?(Array)
      raise UnprocessableEntity, "Missing node list"
    end

    result = @kavlan.update_vlan_nodes(params[:vlan_id], params[:vlans_node][:_json])
    if result.code.to_i == 403
      raise Forbidden, "Not enough privileges on Kavlan resources"
    end

    respond_to do |format|
      format.g5kitemjson { render json: result.body }
      format.json { render json: result.body }
    end
  end

  protected

  def collection_path
    site_vlan_vlans_nodes_path
  end

  def parent_path
    File.join(site_vlans_path, params[:vlan_id])
  end

  def links_for_item(item)
    links = []
    links.push({
      'rel' => 'self',
      'href' => uri_to(File.join(site_vlans_nodes_path, item['uid'])),
      'type' => api_media_type(:g5kitemjson)
    },
    {
      'rel' => 'parent',
      'href' => uri_to(site_vlans_nodes_path),
      'type' => api_media_type(:g5kcollectionjson)
    })

    links
  end

  def links_for_collection
    [
      {
        'rel' => 'self',
        'href' => uri_to(collection_path),
        'type' => api_media_type(:g5kcollectionjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(parent_path),
        'type' => api_media_type(:g5kitemjson)
      }
    ]
  end
end
