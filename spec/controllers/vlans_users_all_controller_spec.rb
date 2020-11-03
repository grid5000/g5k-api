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

describe VlansUsersAllController do
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

  describe 'GET /vlans/users' do
    it 'should return all users having a vlan' do
      stub_request(:get, File.join(@base_expected_uri, 'users')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-users.json'), headers: @headers_return)

      get :index, params: { site_id: 'rennes', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json['total']).to eq(1)
      expect(json['items'].length).to eq(1)
      expect(json['items'].first['uid']).to eq('snoir')
      expect(json['items'].first['links']).to eq([
        {
         'rel'  => 'self',
         'href' => '/sites/rennes/vlans/users/snoir',
         'type' => api_media_type(:g5kitemjson)
        },
        {
         'rel'  => 'parent',
         'href' => '/sites/rennes/vlans/users',
         'type' => api_media_type(:g5kcollectionjson)
        }
      ])
      expect(json['links']).to eq([
        {
         'href' => '/sites/rennes/vlans/users',
         'rel'  => 'self',
         'type' => api_media_type(:g5kcollectionjson)
        },
        {
         'href' => '/sites/rennes/vlans',
         'rel'  => 'parent',
         'type' => api_media_type(:g5kcollectionjson)
        }
      ])
    end

    it 'should get vlans assigned for user' do
      stub_request(:get, File.join(@base_expected_uri, 'users/snoir')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-users-snoir.json'), headers: @headers_return)

      get :show, params: { site_id: 'rennes', user_id: 'snoir', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json['uid']).to eq('snoir')
      expect(json.length).to eq(3)
      expect(json['vlans']).to be_a(Array)
      expect(json['vlans']).to eq(['1'])
      expect(json['links']).to eq([
        {
         'href' => '/sites/rennes/vlans/users/snoir',
         'rel'  => 'self',
         'type' => api_media_type(:g5kitemjson)
        },
        {
         'href' => '/sites/rennes/vlans/users',
         'rel'  => 'parent',
         'type' => api_media_type(:g5kcollectionjson)
        }
      ])
    end
  end
end
