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
  include Swagger::Blocks

  swagger_path "/sites/{siteId}/vlans/nodes" do
    operation :get do
      key :summary, 'List nodes with current vlan.'
      key :description, 'Fetch list of all nodes and their current vlan.'
      key :tags, ['vlan']

      parameter do
        key :$ref, :siteId
      end

      response 200 do
        key :description, 'Collection of nodes.'
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :VlanAllNodeCollection
          end
        end
      end
    end

    operation :post do
      key :summary, 'Ask vlan for nodes.'
      key :description, 'Fetch list of asked nodes and their current vlan.'
      key :tags, ['vlan']

      parameter do
        key :$ref, :siteId
      end

      request_body do
        key :description, 'Asked nodes.'
        key :required, true
        content 'application/json' do
          schema do
            key :type, :array
            key :description, "Nodes list."
            items do
              key :type, :string
              key :format, :hostname
            end
            key :example, ['dahu-3.grenoble.grid5000.fr']
          end
        end
      end

      response 200 do
        key :description, 'Vlans added.'
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :VlanAllNodeCollection
          end
        end
      end

      response 415 do
        content :'text/plain'
        key :description, 'Content-Type not supported.'
      end

      response 422 do
        content :'text/plain'
        key :description, 'Unprocessable data structure.'
      end
    end
  end

  # Display nodes for a vlan
  def index
    allow :get
    expires_in 60.seconds

    nodes = @kavlan.nodes
    result = format_nodes(nodes)

    render_result(result)
  end

  def show
    allow :get
    expires_in 60.seconds

    nodes = @kavlan.nodes(params[:node_name])
    result = { 'uid' => nodes.first[0], 'vlan' => nodes.first[1] }

    raise NotFound, 'Unknown node' if result['vlan'] == 'unknown'

    result['links'] = links_for_item(result)

    render_result(result)
  end

  # Get the vlan for a list of nodes
  def vlan_for_nodes
    ensure_authenticated!
    allow :post

    unless request.content_type == "application/json"
      raise UnsupportedMediaType, request.content_type
    end

    if params[:vlans_nodes_all][:_json].blank? ||
        !params[:vlans_nodes_all][:_json].is_a?(Array)
      raise UnprocessableEntity, "Missing node list"
    end

    nodes = @kavlan.vlan_for_nodes(params[:vlans_nodes_all][:_json])
    nodes = JSON.parse(nodes.body)
    nodes.delete_if { |_key, value| value == 'unknown_node' }

    result = format_nodes(nodes)

    render_result(result)
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
