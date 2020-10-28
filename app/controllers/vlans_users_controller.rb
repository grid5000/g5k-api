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

class VlansUsersController < ApplicationController
  include Vlans

  # List users
  def index
    allow :get
    expires_in 60.seconds

    result = @kavlan.vlan_users(params[:vlan_id])
    result.delete('uid')

    result['items'].each do |item|
      item['links'] = links_for_item(item)
    end
    result['links'] = links_for_collection

    respond_to do |format|
      format.g5kcollectionjson { render json: result }
      format.json { render json: result }
    end
  end

  # Display the rights on a vlan for a user
  def show
    allow :get
    expires_in 60.seconds

    result = @kavlan.vlan_users(params[:vlan_id], params[:id])
    result['links'] = links_for_collection

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  # Remove rights for user on a vlan
  def destroy
    ensure_authenticated!
    allow :delete

    result = @kavlan.delete_user(params[:vlan_id], params[:id])

    if result.code.to_i == 403
      raise Forbidden, 'Not enough privileges on Kavlan resources'
    end

    render plain: '',
           status: result.code
  end

  # Add rights for user on a vlan
  def add
    ensure_authenticated!
    allow :put

    result = @kavlan.add_user(params[:vlan_id], params[:id])

    if result.code.to_i == 403
      raise Forbidden, "Not enough privileges on Kavlan resources"
    end

    render plain: '',
           status: result.code
  end

  protected

  def collection_path
    params[:id] ? site_vlan_vlans_user_path : site_vlan_vlans_users_path
  end

  def parent_path
    if params[:id]
      site_vlan_vlans_users_path
    else
      File.join(site_vlans_path, params[:vlan_id])
    end
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
      'href' => uri_to(File.join(collection_path)),
      'type' => api_media_type(:g5kcollectionjson)
    })

    links
  end

  def links_for_collection
    self_media_type = params[:id] ? :g5kitemjson : :g5kcollectionjson
    parent_media_type = params[:id] ? :g5kcollectionjson : :g5kitemjson

    [
      {
        'rel' => 'self',
        'href' => uri_to(collection_path),
        'type' => api_media_type(self_media_type)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(parent_path),
        'type' => api_media_type(parent_media_type)
      }
    ]
  end
end
