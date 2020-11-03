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

class VlansNodesAllController < ApplicationController
  include Vlans

  # Display nodes for a vlan
  def index
    allow :get
    expires_in 60.seconds

    nodes = @kavlan.nodes
    result = format_nodes(nodes)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  def show
    allow :get
    expires_in 60.seconds

    nodes = @kavlan.nodes(params[:node_name])
    result = { 'uid' => nodes.first[0], 'vlan' => nodes.first[1] }

    raise NotFound, 'Unknown node' if result['vlan'] == 'unknown'

    result['links'] = links_for_item(result)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  # Get the vlan for a list of nodes
  def vlan_for_nodes
    ensure_authenticated!
    allow :post

    unless request.content_type == "application/json"
      raise UnsupportedMediaType, "Content-Type #{request.content_type} not supported"
    end

    if params[:vlans_nodes_all][:_json].blank? ||
        !params[:vlans_nodes_all][:_json].is_a?(Array)
      raise UnprocessableEntity, "Missing node list"
    end

    nodes = @kavlan.vlan_for_nodes(params[:vlans_nodes_all][:_json])
    nodes = JSON.parse(nodes.body)
    nodes.delete_if { |_key, value| value == 'unknown_node' }

    result = format_nodes(nodes)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  protected

  def format_nodes(nodes)
    result = {
      'total' => nodes.length,
      'offset' => 0,
      'items' => nodes.map { |n| {'uid' => n[0], 'vlan' => n[1]} },
      'links' => links_for_collection
    }

    result['items'].each do |item|
      item['links'] = links_for_item(item)
    end

    result
  end

  def collection_path
    site_vlans_nodes_path
  end

  def parent_path
    site_vlans_path
  end

  def links_for_item(item)
    links = []
    links.push({
      'rel' => 'self',
      'href' => uri_to(File.join(collection_path, item['uid'])),
      'type' => api_media_type(:g5kitemjson)
    },
    {
      'rel' => 'parent',
      'href' => uri_to(collection_path),
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
        'type' => api_media_type(:g5kcollectionjson)
      }
    ]
  end
end
