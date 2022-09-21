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
  include Swagger::Blocks

  swagger_path "/sites/{siteId}/vlans/{vlanId}/nodes" do
    operation :get do
      key :summary, 'List nodes in vlan'
      key :description, 'Fetch list of current nodes in vlan.'
      key :tags, ['vlan']

      [:siteId, :vlanId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, 'Collection of nodes.'
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :VlanNodeCollection
          end
        end
      end

      response 404 do
        content :'text/plain'
        key :description, 'Vlan not found.'
      end
    end

    operation :post do
      key :summary, 'Add nodes to vlan'
      key :description, 'Add nodes to vlan.'
      key :tags, ['vlan']

      [:siteId, :vlanId].each do |param|
        parameter do
          key :'$ref', param
        end
      end

      request_body do
        key :description, 'Nodes to add payload.'
        key :required, true
        content 'application/json' do
          schema do
            key :type, :array
            key :description, "Nodes list."
            items do
              key :type, :string
              key :format, :hostname
            end
            key :example, ['dahu-3.grenoble.grid5000.fr',
                           'dahu-10.grenoble.grid5000.fr']
          end
        end
      end

      response 200 do
        key :description, 'Vlans added.'
        content :'application/json' do
          schema do
            key :'$ref', :VlanAddResponse
          end
        end
      end

      response 404 do
        content :'text/plain'
        key :description, 'Vlan not found.'
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

    render_result(result)
  end

  # Add nodes inside a vlan
  def add
    ensure_authenticated!
    allow :post

    unless request.content_type == "application/json"
      raise UnsupportedMediaType, request.content_type
    end

    if params[:vlans_node][:_json].blank? || !params[:vlans_node][:_json].is_a?(Array)
      raise UnprocessableEntity, 'Missing node list'
    end

    kavlan_result = @kavlan.update_vlan_nodes(params[:vlan_id], params[:vlans_node][:_json])

    result = {}
    kavlan_result = JSON.parse(kavlan_result)

    params[:vlans_node][:_json].each do |node|
      result[node] = {}

      if kavlan_result[node] == 'ok'
        result[node][:status] = 'success'
        result[node][:message] = 'Successfully added to vlan'
      elsif kavlan_result[node] == 'unknown_node'
        result[node][:status] = 'failure'
        result[node][:message] = 'Unknown node'
      else
        result[node][:status] = 'unchanged'
        result[node][:message] = 'Node already in vlan'
      end
    end

    render_result(result)
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
