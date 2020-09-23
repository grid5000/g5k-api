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

describe SitesController do
  render_views

  describe 'GET /sites' do
    it 'should get the correct collection of sites' do
      get :index, format: :json
      expect(response.status).to eq 200
      expect(json['total']).to eq 8
      expect(json['items'].length).to eq 8
      expect(json['items'][0]['uid']).to eq 'grenoble'
      expect(json['items'][0]['links']).to be_a(Array)
    end

    it 'should correctly set the URIs when X-Api-Path-Prefix is present' do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      get :index, format: :json
      expect(response.status).to eq 200
      expect(json['links'].find { |l| l['rel'] == 'self' }['href']).to eq '/sid/sites'
    end

    it 'should correctly set the URIs when X-Api-Mount-Path is present' do
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, format: :json
      expect(response.status).to eq 200
      expect(json['links'].find { |l| l['rel'] == 'self' }['href']).to eq '/'
    end

    it 'should correctly set the URIs when X-Api-Mount-Path and X-Api-Path-Prefix are present' do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, format: :json
      expect(response.status).to eq 200
      expect(json['links'].find { |l| l['rel'] == 'self' }['href']).to eq '/sid/'
    end
  end # describe "GET /sites"

  describe 'GET /sites/{{site_id}}' do
    it 'should fail if the site does not exist' do
      get :show, params: { id: 'doesnotexist', format: :json }
      expect(response.status).to eq 404
    end

    it 'should return the site' do
      get :show, params: { id: 'rennes', format: :json }
      expect(response.status).to eq 200
      assert_expires_in(60, public: true)
      expect(json['uid']).to eq 'rennes'
      expect(json['links'].map { |l| l['rel'] }.sort).to eq %w[
        clusters
        deployments
        jobs
        metrics
        network_equipments
        parent
        pdus
        self
        servers
        status
        version
        versions
        vlans
      ]
      expect(json['links'].find do |l|
        l['rel'] == 'self'
      end['href']).to eq '/sites/rennes'
      expect(json['links'].find do |l|
        l['rel'] == 'clusters'
      end['href']).to eq '/sites/rennes/clusters'
      expect(json['links'].find do |l|
        l['rel'] == 'version'
      end['href']).to eq "/sites/rennes/versions/#{@latest_commit}"
    end

    it 'should return link for deployment' do
      get :show, params: { id: 'rennes', format: :json }
      expect(response.status).to eq 200
      expect(json['uid']).to eq 'rennes'
      expect(json['links'].find do |l|
        l['rel'] == 'deployments'
      end['href']).to eq '/sites/rennes/deployments'
    end

    it 'should return link /servers if present in site' do
      get :show, params: { id: 'nancy', format: :json }
      expect(response.status).to eq 200
      expect(json['uid']).to eq 'nancy'
      expect(json['links'].find do |l|
        l['rel'] == 'servers'
      end['href']).to eq '/sites/nancy/servers'
    end

    it 'should return the specified version, and the max-age value in the Cache-Control header should be big' do
      get :show, params: { id: 'rennes', format: :json, version: '2eefdbf0e48cad1bd2db4fa9c96397df168a9c68' }
      expect(response.status).to eq 200
      assert_expires_in(24 * 3600 * 30, public: true)
      expect(json['uid']).to eq 'rennes'
      expect(json['version']).to eq '2eefdbf0e48cad1bd2db4fa9c96397df168a9c68'
      expect(json['links'].find  do |l|
        l['rel'] == 'version'
      end['href']).to eq '/sites/rennes/versions/2eefdbf0e48cad1bd2db4fa9c96397df168a9c68'
    end

    it 'should return 404 if the specified branch does not exist' do
      get :show, params: { id: 'rennes', format: :json, branch: 'doesnotexist' }
      expect(response.status).to eq 404
    end

    it 'should return 404 if the specified version does not exist' do
      get :show, params: { id: 'rennes', format: :json, version: 'doesnotexist' }
      expect(response.status).to eq 404
    end
  end

  describe 'GET /sites/{{site_id}}/status (authenticated)' do
    before do
      authenticate_as('crohr')
    end

    it 'should return 200 and the site status' do
      get :status, params: { id: 'rennes', format: :json }
      expect(response.status).to eq 200
      expect(json['nodes'].length).to eq 75
      expect(json['nodes'].keys.map { |k| k.split('-')[0] }.uniq.sort).to eq %w[
        parapide
        parapluie
        parasilo
      ].sort
      expect(json['vlans']).to be_a(Hash)
      expect(json['vlans'].length).to eq 7
      expect(json['vlans']['1']['type']).to eq 'kavlan-local'
      expect(json['disks']).not_to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).not_to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['free_slots']).not_to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['busy_slots']).not_to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['freeable_slots']).not_to be_nil
      expect(json.keys).to include('uid')
      expect(json['uid']).to eq @now.to_i
    end

    # GET /sites/{{site_id}}/status?network_address={{network_address}}
    it 'should return the status ONLY for the specified node' do
      get :status, params: { id: 'rennes', network_address: 'parapide-5.rennes.grid5000.fr', format: :json }
      expect(response.status).to eq 200
      expect(json['nodes'].keys.map { |k| k.split('.')[0] }.uniq.sort).to eq ['parapide-5']
      expect(json['disks']).to be_empty
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).not_to be_nil
    end

    # GET /sites/{{site_id}}/status?disks=no
    it 'should return the status of nodes but not disks' do
      get :status, params: { id: 'rennes', disks: 'no', format: :json }
      expect(response.status).to eq 200
      expect(json['nodes'].length).to eq 75
      expect(json['nodes'].keys.map { |k| k.split('-')[0] }.uniq.sort).to eq %w[
        parapide
        parapluie
        parasilo
      ].sort
      expect(json['disks']).to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).not_to be_nil
    end

    # GET /sites/{{site_id}}/status?job_details=no
    it 'should return the status without the reservations' do
      get :status, params: { id: 'rennes', job_details: 'no', format: :json }
      expect(response.status).to eq 200
      expect(json['nodes'].length).to eq 75
      expect(json['nodes'].keys.map { |k| k.split('-')[0] }.uniq.sort).to eq %w[
        parapide
        parapluie
        parasilo
      ].sort
      expect(json['disks']).not_to be_nil
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).to be_nil
    end

    it 'should fail gracefully in the event of a grit timeout' do
      expect_any_instance_of(Grid5000::Repository).to receive(:find_commit_for).and_raise(Rugged::RepositoryError)
      get :status, params: { id: 'rennes', job_details: 'no', format: :json }
      expect(response.status).to eq 503
    end
  end # "GET /sites/{{site_id}}/status"

  describe 'GET /sites/{{site_id}}/status (by anonymous)' do
    before do
      authenticate_as('anonymous')
      get :status, params: { id: 'rennes', format: :json }
      expect(response.status).to eq 200
    end

    it 'should not include reservations' do
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).to be_nil
    end
  end
  describe 'GET /sites/{{site_id}}/status (unknown)' do
    # unknown users are authenticated users for which we don't have the precise login
    before do
      authenticate_as('unknown')
      get :status, params: { id: 'rennes', format: :json }
      expect(response.status).to eq 200
    end

    it 'should include reservations' do
      expect(json['nodes']['parapide-5.rennes.grid5000.fr']['reservations']).to_not be_nil
    end
  end

  describe 'GET /sites?deep=true' do
    it "should get the correct deep view of sites" do
      get :index, params: { format: :json, deep: true }
      expect(response.status).to eq 200
      expect(json['items'].length).to eq 8
      expect(json['items']['grenoble'].length).to eq 24
      expect(json['items']['grenoble']).to be_a(Hash)
      expect(json['items']['grenoble']['uid']).to eq 'grenoble'
    end

    it "should be the correct version" do
      get :index, params: { format: :json, deep: true }
      expect(response.status).to eq 200
      expect(json['version']).to eq @latest_commit
    end
  end

  describe "GET /sites/{{id}}?deep=true" do
    it "should get the correct deep view for one site" do
      get :show, params: { id: 'rennes', format: :json, deep: true }
      expect(response.status).to eq 200
      expect(json['total']).to eq 24
      expect(json['items'].length).to eq 24
      expect(json['items']['clusters']).to be_a(Hash)
      expect(json['items']['clusters']['parasilo']['uid']).to eq 'parasilo'
    end
  end

  describe "GET /sites/{{id}}?deep=true&job_id={{job_id}}" do
    it "should get the correct nodes collection for a job" do
      get :show, params: { id: 'rennes', job_id: '374187', format: :json, deep: true }
      expect(response.status).to eq 200
      expect(json['total']).to eq 3
      expect(json['items'].length).to eq 3
      expect(json['items']['clusters']).to be_a(Hash)
      expect(json['items']['clusters']['parapide']['uid']).to eq 'parapide'
      expect(json['items']['clusters']['parapide']['nodes']).to be_a(Array)
      expect(json['items']['clusters']['parapide']['nodes'].first['uid']).to eq 'parapide-1'
      expect(json['items']['clusters']['parapide']['nodes'].length).to eq 16
      expect(json['version']).to eq 'f449f0cb61b0cf5adf1ddbae47c9a409af9652f1'
    end
  end
end
