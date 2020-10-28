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
  include Vlans

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
      item['links'] = links_for_item(item)
    end

    respond_to do |format|
      format.g5kcollectionjson { render json: result }
      format.json { render json: result }
    end
  end

  # Display the details of a vlan
  def show
    allow :get
    expires_in 60.seconds

    result = @kavlan.vlan(params[:id])
    result.delete('links')
    result['links'] = links_for_item(result)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
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

  def vlan_users
    allow :get
    expires_in 60.seconds

    result = @kavlan.vlan_users(params[:id], params[:user_id])

    result['items'].each do |item|
      item['links'] = links_for_item(item)
    end
    result['links'] = links_for_collection

    respond_to do |format|
      format.g5kcollectionjson { render json: result }
      format.json { render json: result }
    end
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
