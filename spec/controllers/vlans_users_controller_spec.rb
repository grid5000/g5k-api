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

require 'spec_helper'

describe VlansUsersController do
  render_views

  before do
    @base_expected_uri = 'http://api-out.local/sites/rennes/internal/kavlanapi/'
    @headers_return = { 'Content-Type' => 'application/json' }

    stub_request(:get, @base_expected_uri).
      with(
        headers: {
          'Accept'=>'application/json',
          'Host'=>'api-out.local',
        }).
      to_return(status: 200, body: fixture('kavlan-rennes-root.json'), headers: @headers_return)
  end

  describe 'GET /vlans/:id/users' do
    it 'should have users for vlan 1' do
      stub_request(:get, File.join(@base_expected_uri, '1', 'users')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-vlan-users-1.json'), headers: @headers_return)

      get :index, params: { site_id: 'rennes', vlan_id: '1', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json['total']).to eq(1)
      expect(json['items'].length).to eq(1)
      expect(json['items'].first['uid']).to eq('snoir')
      expect(json['items'].first['links']).to eq([
        {
         'rel'  => 'self',
         'href' => '/sites/rennes/vlans/1/users/snoir',
         'type' => api_media_type(:g5kitemjson)
        },
        {
         'rel'  => 'parent',
         'href' => '/sites/rennes/vlans/1/users',
         'type' => api_media_type(:g5kcollectionjson)
        }
      ])
      expect(json['links']).to eq([
        {
         'rel'  => 'self',
         'href' => '/sites/rennes/vlans/1/users',
         'type' => api_media_type(:g5kcollectionjson)
        },
        {
         'rel'  => 'parent',
         'href' => '/sites/rennes/vlans/1',
         'type' => api_media_type(:g5kitemjson)
        }
      ])
    end

    it 'should return user as authorized' do
      stub_request(:get, File.join(@base_expected_uri, '1', 'users', 'snoir')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-vlan-users-1-snoir.json'), headers: @headers_return)

      get :show, params: { site_id: 'rennes', vlan_id: '1', id: 'snoir', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json.length).to eq(3)
      expect(json['uid']).to eq('snoir')
      expect(json['status']).to eq('authorized')
      expect(json['links']).to eq([
        {
         'rel'  => 'self',
         'href' => '/sites/rennes/vlans/1/users/snoir',
         'type' => 'application/vnd.grid5000.item+json'
        },
        {
         'rel'  => 'parent',
         'href' => '/sites/rennes/vlans/1/users',
         'type' => 'application/vnd.grid5000.collection+json'
        }
      ])
    end

    it 'should return user as unauthorized' do
      stub_request(:get, File.join(@base_expected_uri, '5', 'users', 'snoir')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 404, headers: @headers_return)

      get :show, params: { site_id: 'rennes', vlan_id: '5', id: 'snoir', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json.length).to eq(3)
      expect(json['uid']).to eq('snoir')
      expect(json['status']).to eq('unauthorized')
      expect(json['links']).to eq([
        {
         'rel'  => 'self',
         'href' => '/sites/rennes/vlans/5/users/snoir',
         'type' => 'application/vnd.grid5000.item+json'
        },
        {
         'rel'  => 'parent',
         'href' => '/sites/rennes/vlans/5/users',
         'type' => 'application/vnd.grid5000.collection+json'
        }
      ])
    end
  end
end
