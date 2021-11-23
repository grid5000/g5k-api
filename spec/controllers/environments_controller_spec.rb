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

describe EnvironmentsController do
  render_views

  before do
    @base_expected_uri = 'http://api-out.local/sites/grenoble/internal/kadeployapi/environments'
    @headers_return = { 'Content-Type' => 'application/json' }
  end

  describe 'GET /environments/' do
    it 'should return the list of latest environments versions' do
      authenticate_as('snoir')
      stub_request(:get, @base_expected_uri + '?last=true').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-last.json'), headers: @headers_return)

      stub_request(:get, @base_expected_uri + '?last=true&username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(76)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(76)
      expect(json['links'].length).to eq(2)
      expect(json['items'].first['uid']).to eq('centos7-min_x86_64_2021090715_deploy')
      expect(json['items'].first.length).to eq(18)
    end

    it 'should return the list of latest only public environments versions if anonymous' do
      authenticate_as('anonymous')
      stub_request(:get, @base_expected_uri + '?last=true').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'anonymous'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-last.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(75)
      expect(json['items'].length).to eq(75)
    end

    it 'should return all environments versions' do
      authenticate_as('snoir')
      stub_request(:get, @base_expected_uri).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble.json'), headers: @headers_return)

      stub_request(:get, @base_expected_uri + '?username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json, latest_only: 'no' }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(941)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(941)
      expect(json['links'].length).to eq(2)
      expect(json['items'].first['uid']).to eq('centos7-min_x86_64_2021090715_deploy')
      expect(json['items'].first.length).to eq(18)
    end

    it 'should return only envs for ppc64le architecture' do
      authenticate_as('snoir')
      stub_request(:get, @base_expected_uri + '?last=true').
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-last.json'), headers: @headers_return)

      stub_request(:get, @base_expected_uri + '?last=true&username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json, arch: 'ppc64le' }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(14)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(14)
      expect(json['links'].length).to eq(2)
      expect(json['items'].first['uid']).to eq('centos7-min_ppc64le_2021090715_deploy')
      expect(json['items'].first.length).to eq(18)
    end

    it 'should return only envs for the specified name' do
      authenticate_as('snoir')
      stub_request(:get, @base_expected_uri).
        with(
          headers: {
            'Accept'=>'application/json',
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('environments-grenoble.json'), headers: @headers_return)

      stub_request(:get, @base_expected_uri + '?username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json,
                            name: 'debian10-base', latest_only: 'no' }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(65)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(65)
      expect(json['links'].length).to eq(2)
      expect(json['items'].map { |i| i['name'] } ).to all(eq('debian10-base'))
      expect(json['items'].first.length).to eq(18)
    end

    it 'should return only envs for the specified user' do
      authenticate_as('snoir')

      stub_request(:get, @base_expected_uri + '?last=true&username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :index, params: { site_id: 'grenoble', format: :json, user: 'snoir' }

      expect(response.status).to eq(200)
      expect(json['total']).to eq(1)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(1)
      expect(json['links'].length).to eq(2)
      expect(json['items'].map { |i| i['name'] } ).to all(eq('debian10-std'))
      expect(json['items'].first.length).to eq(18)
    end

    it 'should return 403 when asking for env of specified user if anonymous' do
      authenticate_as('anonymous')

      get :index, params: { site_id: 'grenoble', format: :json, user: 'snoir' }

      expect(response.status).to eq(403)
      expect(response.body).to eq 'Not allowed to list other users environments, '\
        'because you are seen as an anonymous one'
    end
  end

  describe 'GET /environments/debian10-std_x86_64_2021090715_deploy' do
    it 'should return one environment' do
      authenticate_as('snoir')
      stub_request(:get, @base_expected_uri).
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir'
          }).
          to_return(status: 200, body: fixture('environments-grenoble.json'), headers: @headers_return)

      stub_request(:get, @base_expected_uri + '?username=snoir').
        with(
          headers: {
            'Accept' => 'application/json',
            'Host' => 'api-out.local',
            'X-Api-User-Cn' => 'snoir',
          }).
          to_return(status: 200, body: fixture('environments-grenoble-sno.json'), headers: @headers_return)

      get :show, params: { site_id: 'grenoble', id: 'centos7-min_ppc64le_2021090715_deploy', format: :json }

      expect(response.status).to eq(200)
      expect(json['links'].length).to eq(2)
      expect(json['uid']).to eq('centos7-min_ppc64le_2021090715_deploy')
      expect(json.length).to eq(18)
    end
  end
end
