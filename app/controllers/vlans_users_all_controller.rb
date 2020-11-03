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

class VlansUsersAllController < ApplicationController
  include Vlans

  # List users
  def index
    allow :get
    expires_in 60.seconds

    result = @kavlan.users

    result['items'].each do |item|
      item['links'] = links_for_item(item)
    end
    result['links'] = links_for_collection

    respond_to do |format|
      format.g5kcollectionjson { render json: result }
      format.json { render json: result }
    end
  end

  # Display the vlans allowed for a user
  def show
    allow :get
    expires_in 60.seconds

    result = @kavlan.users(params[:user_id])

    result['links'] = links_for_item(result)

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  protected

  def collection_path
    site_vlans_users_path(params[:site_id])
  end

  def parent_path
    site_vlans_path(params[:site_id])
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
