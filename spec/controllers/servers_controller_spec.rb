# Copyright (c) 2015-2016 Anirvan BASU, INRIA Rennes - Bretagne Atlantique
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

describe ServersController do
  render_views

  describe 'GET /sites/{{site_id}}/servers/{{id}}' do
    # The following unit tests check the responses at level of specific servers.

    it 'should return ONLY cluster talc-data in nancy' do
      get :show, params: { branch: 'master', site_id: 'nancy', id: 'talc-data', format: :json }
      assert_media_type(:json)
      cluster_output = '{"alias":[],"kind":"physical","monitoring":{"metric":"power","wattmeter":"multiple"},"network_adapters":{"bmc":{"ip":"172.17.79.21"},"default":{"ip":"172.16.79.21"}},"sensors":{"network":{"available":true,"resolution":1},"power":{"available":true,"resolution":1,"via":{"pdu":[{"port":21,"uid":"grisou-pdu1"},{"port":21,"uid":"grisou-pdu2"}]}}},"serial":"92ZLL82","type":"server","uid":"talc-data","warranty":"2022-11","version":"' + @latest_commit + '","links":[{"rel":"self","type":"application/vnd.grid5000.item+json","href":"/sites/nancy/servers/talc-data"},{"rel":"parent","type":"application/vnd.grid5000.item+json","href":"/sites/nancy"},{"rel":"version","type":"application/vnd.grid5000.item+json","href":"/sites/nancy/servers/talc-data/versions/' + @latest_commit + '"},{"rel":"versions","type":"application/vnd.grid5000.collection+json","href":"/sites/nancy/servers/talc-data/versions"}]}'
      expect(response.body).to eq(cluster_output)
      expect(response.status).to eq(200)
    end
  end

  describe 'GET /sites/{{site_id}}/servers' do
    # The following unit tests check the responses at level of all servers in a site

    it 'should return 47 servers in site nancy their names' do
      get :index, params: { branch: 'master', site_id: 'nancy', format: :json }
      assert_media_type(:json)
      expect(response.status).to eq(200)
      expect(json['total']).to eq(47)

      server_list = []
      json['items'].each do |server|
        server_list = [server['uid']] | server_list
      end
      expect(server_list).to include('api-proxy', 'ci-runner')
    end
  end

  describe 'GET /sites/{{site_id}}/servers?deep=true' do
    it 'should return 47 servers in site nancy and their exact names' do
      get :index, params: { deep: true, site_id: 'nancy', format: :json }
      expect(response.status).to eq(200)
      expect(json['total']).to eq(47)
      expect(json['items']).to be_a(Array)

      server_list = []
      json['items'].each do |server|
        server_list = [server['uid']] | server_list
      end
      expect(server_list).to include('api-proxy', 'ci-runner')
    end

    it 'should return 2 links, parent and self' do
      get :index, params: { deep: true, site_id: 'nancy', format: :json }
      expect(response.status).to eq(200)
      expect(json['links'].length).to eq(2)

      links_rel = []
      json['links'].each do |link|
        links_rel = [link['rel']] | links_rel
      end
      expect(links_rel - %w[self parent]).to be_empty
    end
  end
end
