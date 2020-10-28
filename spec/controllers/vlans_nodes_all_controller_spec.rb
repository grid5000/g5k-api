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

describe VlansNodesAllController do
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

  describe 'GET /vlans/nodes' do
    it 'should return all the nodes' do
      stub_request(:get, File.join(@base_expected_uri, 'nodes')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('kavlan-rennes-nodes.json'), headers: @headers_return)

      get :index, params: { site_id: 'rennes', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json.length).to eq(4)
      expect(json['total']).to eq(257)
      expect(json['items'].length).to eq(257)
      expect(json['items'].first['uid']).to eq('paranoia-1-eth1.rennes.grid5000.fr')
      expect(json['items'].first['vlan']).to eq('DEFAULT')
      expect(json['items'].first['links']).to eq([
        {
         'rel'=>'self',
         'href'=>'/sites/rennes/vlans/nodes/paranoia-1-eth1.rennes.grid5000.fr',
         'type'=>'application/vnd.grid5000.item+json'
        },
        {
         'rel'=>'parent',
         'href'=>'/sites/rennes/vlans/nodes',
         'type'=>'application/vnd.grid5000.collection+json'
        }
      ])
      expect(json['links']).to eq([
        {
          'rel'=>'self',
          'href'=>'/sites/rennes/vlans/nodes',
          'type'=>'application/vnd.grid5000.collection+json'
        },
        {
          'rel'=>'parent',
          'href'=>'/sites/rennes/vlans',
          'type'=>'application/vnd.grid5000.collection+json'
        }
      ])
    end

    it 'should return a node' do
      stub_request(:get, File.join(@base_expected_uri, 'nodes', 'paravance-9.rennes.grid5000.fr')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: '{"paravance-9.rennes.grid5000.fr":"DEFAULT"}', headers: @headers_return)

      get :show, params: { site_id: 'rennes', node_name: 'paravance-9.rennes.grid5000.fr', format: :json }

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json.length).to eq(3)
      expect(json['uid']).to eq('paravance-9.rennes.grid5000.fr')
      expect(json['vlan']).to eq('DEFAULT')
      expect(json['links']).to eq([
        {
          'rel'=>'self',
          'href'=>'/sites/rennes/vlans/nodes/paravance-9.rennes.grid5000.fr',
          'type'=>'application/vnd.grid5000.item+json'
        },
        {
          'rel'=>'parent',
          'href'=>'/sites/rennes/vlans/nodes',
          'type'=>'application/vnd.grid5000.collection+json'
        }
      ])
    end
  end

  describe 'POST /vlans/nodes' do
    it 'should return a list of nodes' do
      stub_request(:post, File.join(@base_expected_uri, 'nodes')).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          },
          body: {"nodes" => ['paravance-9.rennes.grid5000.fr',
                             'paravance-10.rennes.grid5000.fr']}
          ).
          to_return(status: 200,
                    body: '{"paravance-9.rennes.grid5000.fr":"DEFAULT",
                            "paravance-10.rennes.grid5000.fr":"1"}',
                    headers: @headers_return)

      authenticate_as('snoir')
      request.content_type = 'application/json'

      post :vlan_for_nodes, params: { site_id: 'rennes',
                                      format: :json,
                                      _json: ['paravance-9.rennes.grid5000.fr',
                                              'paravance-10.rennes.grid5000.fr']}

      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      expect(json.length).to eq(4)
      expect(json['total']).to eq(2)
      expect(json['items'].length).to eq(2)
      expect(json['items'].first['uid']).to eq('paravance-9.rennes.grid5000.fr')
      expect(json['items'].first['vlan']).to eq('DEFAULT')
      expect(json['items'].first['links']).to eq([
        {
          'rel'=>'self',
          'href'=>'/sites/rennes/vlans/nodes/paravance-9.rennes.grid5000.fr',
          'type'=>'application/vnd.grid5000.item+json'
        },
        {
          'rel'=>'parent',
          'href'=>'/sites/rennes/vlans/nodes',
          'type'=>'application/vnd.grid5000.collection+json'
        }
      ])
      expect(json['links']).to eq([
        {
          'rel'=>'self',
          'href'=>'/sites/rennes/vlans/nodes',
          'type'=>'application/vnd.grid5000.collection+json'
        },
        {
          'rel'=>'parent',
          'href'=>'/sites/rennes/vlans',
          'type'=>'application/vnd.grid5000.collection+json'
        }
      ])
    end
  end
end
