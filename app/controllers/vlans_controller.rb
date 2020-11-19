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

class VlansController < ApplicationController
  include Swagger::Blocks
  include Vlans

  swagger_path "/sites/{siteId}/vlans" do
    operation :get do
      key :summary, 'List vlans'
      key :description, 'Fetch the list of all the vlans for site.'
      key :tags, ['vlan']

      parameter do
        key :$ref, :siteId
      end

      response 200 do
        content :'application/json' do
          schema do
            key :'$ref', :VlanCollection
          end
        end

        key :description, 'Vlan collection for site.'
      end
    end
  end

  # List vlans
  def index
    allow :get

    items = @kavlan.list
    total = items.length

    result = {
      'total' => total,
      'offset' => 0,
      'items' => items,
      'links' => links_for_collection
    }

    result['items'].each do |item|
      replace_kavlan_remote(item)
      item['links'] = links_for_item(item)
    end

    respond_to do |format|
      format.g5kcollectionjson { render json: result }
      format.json { render json: result }
    end
  end

  swagger_path "/sites/{siteId}/vlans/{vlanId}" do
    operation :get do
      key :summary, 'Get vlan'
      key :description, 'Fetch the list of all the vlans for site.'
      key :tags, ['vlan']

      [:siteId, :vlanId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content :'application/json' do
          schema do
            key :'$ref', :Vlan
          end
        end

        key :description, 'A specific vlan.'
      end

      response 404 do
        content :'text/plain'

        key :description, 'Vlan not found.'
      end
    end
  end

  # Display the details of a vlan
  def show
    allow :get
    expires_in 60.seconds

    result = @kavlan.vlan(params[:id])
    result.delete('links')
    result['links'] = links_for_item(result)
    replace_kavlan_remote(result)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  swagger_path "/sites/{siteId}/vlans/{vlanId}/dhcpd" do
    operation :put do
      key :summary, 'Start/stop dhcpd'
      key :description, 'Start or stop dhcp server for vlan.'
      key :tags, ['vlan']

      [:siteId, :vlanId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      request_body do
        key :description, 'dhcp action payload.'
        key :required, true
        content 'application/json' do
          schema do
            property :action do
              key :type, :string
              key :description, "Action to perform, 'start' or 'stop'"
              key :example, 'start'
            end
          end
        end
      end

      response 204 do
        key :description, 'dhcp server successfully started or stopped.'
      end

      response 403 do
        content :'text/plain'
        key :description, 'Not enough privileges on kavlan resource to perform action.'
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

  # start/stop dhcpd server for a vlan
  def dhcpd
    ensure_authenticated!
    allow :put

    unless request.content_type == "application/json"
      raise UnsupportedMediaType, "Content-Type #{request.content_type} not supported"
    end

    if params[:vlan].nil? || params[:vlan][:action].nil? ||
        (params[:vlan][:action] != 'start' &&
         params[:vlan][:action] != 'stop')
      raise UnprocessableEntity, "An action ('start' or 'stop') should be provided"
    end

    result = @kavlan.dhcpd(params[:id], params[:vlan])

    if result.code.to_i == 403
      raise Forbidden, "Not enough privileges on Kavlan resources"
    end

    render plain: '',
           status: result.code
  end

  protected

  def collection_path
    site_vlans_path(params[:site_id])
  end

  def parent_path
    site_path(params[:site_id])
  end

  def resource_path(id)
    File.join(collection_path, id.to_s)
  end

  def links_for_item(item)
    links = []
    %w[dhcpd nodes].each do |rel|
      links.push({
        'rel' => rel,
        'type' => api_media_type(:g5kitemjson),
        'href' => uri_to(File.join(resource_path(item['uid']), rel))
      })
    end

    links.push({
      'rel' => 'users',
      'type' => api_media_type(:g5kcollectionjson),
      'href' => uri_to(File.join(resource_path(item['uid']), 'users'))
    },
    {
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
        'rel' => 'nodes',
        'href' => uri_to(File.join(collection_path, 'nodes')),
        'type' => api_media_type(:g5kcollectionjson)
      },
      {
        'rel' => 'users',
        'href' => uri_to(File.join(collection_path, 'users')),
        'type' => api_media_type(:g5kcollectionjson)
      },
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

  private

  def replace_kavlan_remote(item)
    item['type'] = 'kavlan-global-remote' if item['type'] == 'kavlan-remote'
  end
end
