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

describe VlansController do
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

  describe 'GET /vlans/' do
    it 'should return the list of vlans' do
      get :index, params: { site_id: 'rennes', format: :json }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(22)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(22)
      expect(json['links'].length).to eq(2)
      expect(json['items'].first['uid']).to eq('DEFAULT')
      expect(json['items'].map { |i| i['uid'].to_i }.sort).to eq (0..21).to_a.sort

      expect(json['items'].all? { |i| i.has_key?('links') }).to be true

      expect(json['items'][0]['links']).to eq([
        {
          'rel' => 'dhcpd',
          'href' => '/sites/rennes/vlans/DEFAULT/dhcpd',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'nodes',
          'href' => '/sites/rennes/vlans/DEFAULT/nodes',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'users',
          'href' => '/sites/rennes/vlans/DEFAULT/users',
          'type' => api_media_type(:g5kcollectionjson)
        },
        {
          'rel' => 'self',
          'href' => '/sites/rennes/vlans/DEFAULT',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => '/sites/rennes/vlans',
          'type' => api_media_type(:g5kcollectionjson)
        }
      ])
      expect(json['links']).to eq([
        {
          'rel' => 'self',
          'href' => '/sites/rennes/vlans',
          'type' => api_media_type(:g5kcollectionjson)
        },
        {
          'rel' => 'parent',
          'href' => '/sites/rennes',
          'type' => api_media_type(:g5kitemjson)
        }
      ])
    end

    it 'vlan should be valid' do
      stub_request(:get, File.join(@base_expected_uri, '3')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-vlan.json'), headers: @headers_return)

      get :show, params: { site_id: 'rennes', id: '3', format: :json }


      expect(response.status).to eq(200)
      expect(json.length).to eq(3)
      expect(json['uid']).to eq('3')
      expect(json['type']).to eq('kavlan-local')
      expect(json['links'].length).to eq(5)

      expect(json['links']).to eq([
        {
          'rel' => 'dhcpd',
          'href' => '/sites/rennes/vlans/3/dhcpd',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'nodes',
          'href' => '/sites/rennes/vlans/3/nodes',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'users',
          'href' => '/sites/rennes/vlans/3/users',
          'type' => api_media_type(:g5kcollectionjson)
        },
        {
          'rel' => 'self',
          'href' => '/sites/rennes/vlans/3',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => '/sites/rennes/vlans',
          'type' => api_media_type(:g5kcollectionjson)
        }
      ])
    end

    it 'should return 404 if vlan does not exist' do
      get :show, params: { site_id: 'rennes', id: '200', format: :json }

      expect(response.status).to eq(404)
      expect(response.body).to eq('Vlan 200 does not exist')
    end

    it 'vlan should be type kavlan-global-remote' do
      stub_request(:get, File.join(@base_expected_uri, '15')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-vlan-remote.json'), headers: @headers_return)

      get :show, params: { site_id: 'rennes', id: '15', format: :json }


      expect(response.status).to eq(200)
      expect(json['uid']).to eq('15')
      expect(json['type']).to eq('kavlan-global-remote')
    end
  end

  describe 'PUT /vlans/:id/dhcpd' do
    it 'should return 422 when wrong or missing dhcpd action' do
      stub_request(:put, File.join(@base_expected_uri, '1', 'dhcpd')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 204, headers: @headers_return)

      authenticate_as('snoir')
      request.content_type = 'application/json'
      put :dhcpd, params: { site_id: 'rennes', id: '1', format: :json }

      expect(response.status).to eq(422)
      expect(response.body).to eq("An action ('start' or 'stop') should be provided")
    end

    it 'should return 204 when starting dhcpd' do
      stub_request(:put, File.join(@base_expected_uri, '1', 'dhcpd')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 204, headers: @headers_return)

      authenticate_as('snoir')
      request.content_type = 'application/json'
      put :dhcpd, params: { site_id: 'rennes', id: '1', action: 'start', format: :json }

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
    end
  end
end
