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

describe DeploymentsController do
  render_views

  before do
    @now = Time.now
    10.times do |i|
      FactoryBot.create(:deployment, uid: "uid#{i}", created_at: (@now + i).to_i)
    end
  end

  describe 'GET /sites/{{site_id}}/deployments' do
    it 'should return the list of deployments with the correct links, in created_at DESC order' do
      get :index, params: { site_id: 'rennes', format: :json }
      expect(response.status).to eq(200)
      expect(json['total']).to eq(10)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(10)
      expect(json['items'].map { |i| i['uid'] }).to eq((0...10).map { |i| "uid#{i}" }.reverse)

      expect(json['items'].all? { |i| i.has_key?('links') }).to be true

      expect(json['items'][0]['links']).to eq([
                                                {
                                                  'rel' => 'self',
                                                  'href' => '/sites/rennes/deployments/uid9',
                                                  'type' => api_media_type(:g5kitemjson)
                                                },
                                                {
                                                  'rel' => 'parent',
                                                  'href' => '/sites/rennes',
                                                  'type' => api_media_type(:g5kitemjson)
                                                }
                                              ])
      expect(json['links']).to eq([
                                    {
                                      'rel' => 'self',
                                      'href' => '/sites/rennes/deployments',
                                      'type' => api_media_type(:g5kcollectionjson)
                                    },
                                    {
                                      'rel' => 'parent',
                                      'href' => '/sites/rennes',
                                      'type' => api_media_type(:g5kitemjson)
                                    }
                                  ])
    end
    it 'should correctly deal with pagination filters' do
      get :index, params: { site_id: 'rennes', offset: 3, limit: 5, format: :json }
      expect(response.status).to eq(200)
      expect(json['total']).to eq(10)
      expect(json['offset']).to eq(3)
      expect(json['items'].length).to eq(5)
      expect(json['items'].map { |i| i['uid'] }).to eq((0...10).map { |i| "uid#{i}" }.reverse.slice(3, 5))
    end
  end # describe "GET /sites/{{site_id}}/deployments"

  describe 'GET /sites/{{site_id}}/deployments/{{id}}' do
    it 'should return 404 if the deployment does not exist' do
      get :show, params: { site_id: 'rennes', id: 'doesnotexist', format: :json }
      expect(response.status).to eq(404)
      expect(response.body).to match(/Couldn't find Grid5000::Deployment with ID=doesnotexist/)
    end
    it 'should return 200 and the deployment' do
      expected_uid = 'uid1'
      get :show, params: { site_id: 'rennes', id: expected_uid, format: :json }
      expect(response.status).to eq(200)
      expect(json['uid']).to eq(expected_uid)
      expect(json['links']).to be_a(Array)
      expect(json.keys.sort).to eq(%w[created_at disable_bootloader_install disable_disk_partitioning environment ignore_nodes_deploying links nodes site_uid status uid updated_at user_uid])
    end
  end # describe "GET /sites/{{site_id}}/deployments/{{id}}"

  describe 'POST /sites/{{site_id}}/deployments' do
    before do
      @valid_attributes = {
        'nodes' => ['paradent-1.rennes.grid5000.fr'],
        'environment' => 'lenny-x64-base'
      }
      @deployment = Grid5000::Deployment.new(@valid_attributes)
    end

    it 'should return 403 if the user is not authenticated' do
      authenticate_as('')
      post :create, params: { site_id: 'rennes', format: :json }
      expect(response.status).to eq(403)
      expect(response.body).to eq('You are not authorized to access this resource')
    end

    it 'should fail if the deployment is not valid' do
      authenticate_as('crohr')
      payload = @valid_attributes.merge('nodes' => [])

      post :create, params: { site_id: 'rennes', format: :json }, body: payload.to_json, as: :json

      expect(response.status).to eq(400)
      expect(response.body).to match(/The deployment you are trying to submit is not valid/)
    end

    it 'should raise an error if an error occurred when launching the deployment' do
      expect(Grid5000::Deployment).to receive(:new).with(@valid_attributes)
                                                   .and_return(@deployment)
      expect(@deployment).to receive(:launch_workflow!).and_raise(Exception.new('some error message'))

      authenticate_as('crohr')

      post :create, params: { site_id: 'rennes', format: :json }, body: @valid_attributes.to_json, as: :json

      expect(response.status).to eq(500)
      expect(response.body).to eq('Cannot launch deployment: some error message')
    end

    it 'should return 500 if the deploymet cannot be launched' do
      expect(Grid5000::Deployment).to receive(:new).with(@valid_attributes)
                                                   .and_return(@deployment)

      expect(@deployment).to receive(:launch_workflow!).and_return(nil)

      authenticate_as('crohr')

      post :create, params: { site_id: 'rennes', format: :json }, body: @valid_attributes.to_json, as: :json

      expect(response.status).to eq(500)
      expect(response.body).to eq('Cannot launch deployment: Uid must be set')
    end

    it 'should call transform_blobs_into_files! before sending the deployment, and return 201 if OK' do
      expect(Grid5000::Deployment).to receive(:new).with(@valid_attributes)
                                                   .and_return(@deployment)

      expect(@deployment).to receive(:transform_blobs_into_files!)
        .with(
          Rails.tmp,
          'http://api-in.local/sites/rennes/files'
        )

      expect(@deployment).to receive(:launch_workflow!).and_return(true)
      @deployment.uid = 'kadeploy-api-provided-wid'

      authenticate_as('crohr')

      post :create, params: { site_id: 'rennes', format: :json }, body: @valid_attributes.to_json, as: :json

      expect(response.status).to eq(201)
      expect(response.headers['Location']).to eq('http://api-in.local/sites/rennes/deployments/kadeploy-api-provided-wid')

      expect(json['uid']).to eq('kadeploy-api-provided-wid')
      expect(json['links']).to be_a(Array)
      expect(json.keys.sort).to eq(%w[created_at disable_bootloader_install disable_disk_partitioning environment ignore_nodes_deploying links nodes site_uid status uid updated_at user_uid])

      dep = Grid5000::Deployment.find_by(uid: 'kadeploy-api-provided-wid')
      expect(dep).not_to be_nil
      expect(dep.status?(:processing)).to be true
    end
  end # describe "POST /sites/{{site_id}}/deployments"

  describe 'DELETE /sites/{{site_id}}/deployments/{{id}}' do
    before do
      @deployment = Grid5000::Deployment.first
    end

    it 'should return 403 if the user is not authenticated' do
      authenticate_as('')
      delete :destroy, params: { site_id: 'rennes', id: @deployment.uid, format: :json }
      expect(response.status).to eq(403)
      expect(response.body).to eq('You are not authorized to access this resource')
    end

    it 'should return 404 if the deployment does not exist' do
      authenticate_as('crohr')
      delete :destroy, params: { site_id: 'rennes', id: 'doesnotexist', format: :json }
      expect(response.status).to eq(404)
      expect(response.body).to eq("Couldn't find Grid5000::Deployment with ID=doesnotexist")
    end

    it 'should return 403 if the requester does not own the deployment' do
      authenticate_as(@deployment.user_uid + 'whatever')
      delete :destroy, params: { site_id: 'rennes', id: @deployment.uid, format: :json }
      expect(response.status).to eq(403)
      expect(response.body).to eq('You are not authorized to access this resource')
    end

    it 'should do nothing and return 204 if the deployment is not in an active state' do
      expect(Grid5000::Deployment).to receive(:find_by)
        .with({:uid => @deployment.uid})
        .and_return(@deployment)

      expect(@deployment).to receive(:can_cancel?).and_return(false)

      authenticate_as(@deployment.user_uid)

      delete :destroy, params: { site_id: 'rennes', id: @deployment.uid, format: :json }

      expect(response.status).to eq(202)
      expect(response.headers['Location']).to eq("http://api-in.local/sites/rennes/deployments/#{@deployment.uid}")
      expect(response.body).to be_empty
    end

    it 'should call Grid5000::Deployment#cancel! if deployment active' do
      expect(Grid5000::Deployment).to receive(:find_by)
        .with({:uid => @deployment.uid})
        .and_return(@deployment)

      expect(@deployment).to receive(:can_cancel?).and_return(true)
      expect(@deployment).to receive(:cancel!).and_return(true)

      authenticate_as(@deployment.user_uid)

      delete :destroy, params: { site_id: 'rennes', id: @deployment.uid, format: :json }

      expect(response.status).to eq(202)
      expect(response.body).to be_empty
      expect(response.headers['Location']).to eq("http://api-in.local/sites/rennes/deployments/#{@deployment.uid}")
    end
  end # describe "DELETE /sites/{{site_id}}/deployments/{{id}}"

  describe 'PUT /sites/{{site_id}}/deployments/{{id}}' do
    before do
      @deployment = Grid5000::Deployment.first
    end

    it 'should return 404 if the deployment does not exist' do
      authenticate_as('crohr')
      put :update, params: { site_id: 'rennes', id: 'doesnotexist', format: :json }
      expect(response.status).to eq(404)
      expect(response.body).to eq("Couldn't find Grid5000::Deployment with ID=doesnotexist")
    end

    it 'should call Grid5000::Deployment#touch!' do
      expect(Grid5000::Deployment).to receive(:find_by)
        .with({:uid => @deployment.uid})
        .and_return(@deployment)

      expect(@deployment).to receive(:active?).and_return(true)
      expect(@deployment).to receive(:touch!)

      put :update, params: { site_id: 'rennes', id: @deployment.uid, format: :json }

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
      expect(response.headers['Location']).to eq("http://api-in.local/sites/rennes/deployments/#{@deployment.uid}")
    end
  end # describe "PUT /sites/{{site_id}}/deployments/{{id}}"
end
