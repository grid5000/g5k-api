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

describe JobsController do
  render_views
  before do
    @job_uids = [374_196, 374_195, 374_194, 374_193, 374_192, 374_191, 374_190, 374_189, 374_188, 374_187, 374_185, 374_186, 374_184, 374_183, 374_182, 374_181, 374_180, 374_179, 374_178, 374_177, 374_176, 374_175, 374_174, 374_173, 374_172, 374_197, 374_198, 374_199, 374_205, 374_210]
  end

  describe 'GET /sites/{{site_id}}/jobs' do
    it 'should fetch the list of jobs, with their links' do
      get :index, params: { site_id: 'rennes', format: :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq @job_uids.length
      expect(json['offset']).to eq 0
      expect(json['items'].length).to eq @job_uids.length
      expect(json['items'].map { |i| i['uid'] }.sort).to eq @job_uids.sort
      expect(json['items'].all? { |i| i.has_key?('links') }).to be true
      expect(json['items'][0]['links']).to eq [
        {
          'rel' => 'self',
          'href' => '/sites/rennes/jobs/374210',
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => '/sites/rennes',
          'type' => api_media_type(:g5kitemjson)
        }
      ]
      expect(json['links']).to eq [
        {
          'rel' => 'self',
          'href' => '/sites/rennes/jobs',
          'type' => api_media_type(:g5kcollectionjson)
        },
        {
          'rel' => 'parent',
          'href' => '/sites/rennes',
          'type' => api_media_type(:g5kitemjson)
        }
      ]
    end

    it 'should fetch the list of jobs, with their resources' do
      get :index, params: { site_id: 'rennes', resources: 'yes', format: :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq @job_uids.length
      expect(json['offset']).to eq 0
      expect(json['items'].length).to eq @job_uids.length
      expect(json['items'].map { |i| i['uid'] }.sort).to eq @job_uids.sort
      expect(json['items'].first.has_key?('assigned_nodes')).to be true
      expect(json['items'].first.has_key?('resources_by_type')).to be true
      expect(json['items'].first['assigned_nodes']).to eq ['parasilo-3.rennes.grid5000.fr']
      expect(json['items'].first['resources_by_type']['cores']).to eq ['parasilo-3.rennes.grid5000.fr/16', 'parasilo-3.rennes.grid5000.fr/17', 'parasilo-3.rennes.grid5000.fr/18', 'parasilo-3.rennes.grid5000.fr/19', 'parasilo-3.rennes.grid5000.fr/20', 'parasilo-3.rennes.grid5000.fr/21', 'parasilo-3.rennes.grid5000.fr/22', 'parasilo-3.rennes.grid5000.fr/23']
    end

    it 'should correctly deal with pagination filters' do
      get :index, params: { site_id: 'rennes', offset: 11, limit: 5, format: :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq @job_uids.length
      expect(json['offset']).to eq 11
      expect(json['items'].length).to eq 5
      expect(json['items'].map { |i| i['uid'] }).to eq [374_190, 374_189, 374_188, 374_187, 374_186]
    end

    it 'should correctly deal with other filters' do
      params = { user: 'crohr', name: 'whatever' }
      expect(OAR::Job).to receive(:list).with(hash_including(params))
                                        .and_return(OAR::Job.limit(5))
      get :index, params: params.merge(site_id: 'rennes', format: :json)
      expect(response.status).to eq 200
    end
  end # describe "GET /sites/{{site_id}}/jobs"

  describe 'GET /sites/{{site_id}}/jobs/{{id}}' do
    it 'should return 404 if the job does not exist' do
      get :show, params: { site_id: 'rennes', id: 'doesnotexist', format: :json }
      expect(response.status).to eq 404
      expect(response.body).to eq "Couldn't find OAR::Job with 'job_id'=doesnotexist"
    end
    it 'should return 200 and the job' do
      get :show, params: { site_id: 'rennes', id: @job_uids[5], format: :json }
      expect(response.status).to eq 200
      expect(json['uid']).to eq @job_uids[5]
      expect(json['links']).to be_a(Array)
      expect(json.keys.sort).to eq %w[assigned_nodes command directory events links message mode project properties queue resources_by_type scheduled_at started_at state submitted_at types uid user user_uid walltime]
      expect(json['types']).to eq ['deploy']
      expect(json['scheduled_at']).to eq 1_294_395_995
      expect(json['assigned_nodes'].sort).to eq ['paramount-4.rennes.grid5000.fr', 'paramount-30.rennes.grid5000.fr', 'paramount-32.rennes.grid5000.fr', 'paramount-33.rennes.grid5000.fr'].sort
      expect(json['resources_by_type']['cores']).to eq ['paramount-4.rennes.grid5000.fr/0', 'paramount-4.rennes.grid5000.fr/1', 'paramount-4.rennes.grid5000.fr/2', 'paramount-4.rennes.grid5000.fr/3', 'paramount-30.rennes.grid5000.fr/0', 'paramount-30.rennes.grid5000.fr/1', 'paramount-30.rennes.grid5000.fr/2', 'paramount-30.rennes.grid5000.fr/3', 'paramount-32.rennes.grid5000.fr/0', 'paramount-32.rennes.grid5000.fr/1', 'paramount-32.rennes.grid5000.fr/2', 'paramount-32.rennes.grid5000.fr/3', 'paramount-33.rennes.grid5000.fr/0', 'paramount-33.rennes.grid5000.fr/1', 'paramount-33.rennes.grid5000.fr/2', 'paramount-33.rennes.grid5000.fr/3']
    end
  end # describe "GET /sites/{{site_id}}/jobs/{{id}}"

  describe 'POST /sites/{{site_id}}/jobs' do
    before do
      @valid_job_attributes = { 'command' => 'sleep 3600' }
    end
    after do
      suppress(Exception) do
        OAR::Job.find(961_722).delete
      end
    end
    it 'should return 403 if the user is not authenticated' do
      authenticate_as('')
      post :create, params: { site_id: 'rennes', format: :json }
      expect(response.status).to eq 403
      expect(response.body).to eq 'You are not authorized to access this resource'
    end
    it 'should return 403 if the user is anonymous' do
      authenticate_as('anonymous')
      post :create, params: { site_id: 'rennes', format: :json }
      expect(response.status).to eq 403
      expect(response.body).to eq 'You are not authorized to access this resource'
    end
    it 'should fail if the OAR api does not return 201, 202 or 400' do
      payload = @valid_job_attributes
      authenticate_as('crohr')

      expected_url = 'http://api-out.local/sites/rennes/internal/oarapi/jobs.json'
      stub_request(:post, expected_url)
        .with(
          headers: {
            'Accept' => api_media_type(:json),
            'Content-Type' => api_media_type(:json),
            'X-Remote-Ident' => 'crohr',
            'X-Api-User-Cn' => 'crohr'
          },
          body: Grid5000::Job.new(payload).to_hash(destination: 'oar-2.4-submission').to_json
        )
        .to_return(
          headers: { 'Location' => expected_url },
          status: [400, 'Bad Request'],
          body: 'some error'
        )

      post :create, params: { site_id: 'rennes', format: :json }, body: payload.to_json, as: :json
      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{expected_url} failed with status 400: some error"
    end

    it 'should return a 400 error if the OAR API returns 400 error code' do
      payload = @valid_job_attributes.merge('resources' => "{ib30g='YES'}/nodes=2")
      authenticate_as('crohr')

      expected_url = 'http://api-out.local/sites/rennes/internal/oarapi/jobs.json'
      stub_request(:post, expected_url)
        .with(
          headers: {
            'Accept' => api_media_type(:json),
            'Content-Type' => api_media_type(:json),
            'X-Remote-Ident' => 'crohr',
            'X-Api-User-Cn' => 'crohr'
          },
          body: Grid5000::Job.new(payload).to_hash(destination: 'oar-2.4-submission').to_json
        )
        .to_return(
          status: [400, 'Bad Request'],
          body: 'Bad Request',
          headers: { 'Location' => expected_url }
        )

      post :create, params: { site_id: 'rennes', format: :json }, body: payload.to_json, as: :json

      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{expected_url} failed with status 400: Bad Request"
    end

    it 'should return a 401 error if the OAR API returns 401 error code' do
      payload = @valid_job_attributes
      authenticate_as('xyz')

      expected_url = 'http://api-out.local/sites/rennes/internal/oarapi/jobs.json'
      stub_request(:post, expected_url)
        .with(
          headers: {
            'Accept' => api_media_type(:json),
            'Content-Type' => api_media_type(:json),
            'X-Remote-Ident' => 'xyz',
            'X-Api-User-Cn' => 'xyz'
          },
          body: Grid5000::Job.new(payload).to_hash(destination: 'oar-2.4-submission').to_json
        )
        .to_return(
          status: [401, 'Authorization Required'],
          body: 'Authorization Required',
          headers: { 'Location' => expected_url }
        )

      post :create, params: { site_id: 'rennes', format: :json }, body: payload.to_json, as: :json

      expect(response.status).to eq 401
      expect(response.body).to eq "Request to #{expected_url} failed with status 401: Authorization Required"
    end

    it 'should return 201, the job details, and the Location header' do
      payload = @valid_job_attributes
      authenticate_as('crohr')

      expected_url = 'http://api-out.local/sites/rennes/internal/oarapi/jobs.json'
      stub_request(:post, expected_url)
        .with(
          headers: {
            'Accept' => api_media_type(:json),
            'Content-Type' => api_media_type(:json),
            'X-Remote-Ident' => 'crohr',
            'X-Api-User-Cn' => 'crohr'
          },
          body: Grid5000::Job.new(payload).to_hash(destination: 'oar-2.4-submission').to_json
        )
        .to_return(lambda { |_|
                     # use a side_effect to really test active_record finders
                     create(:job, job_id: 961_722)
                     {
                       status: 201,
                       body: fixture('oarapi-submitted-job.json')
                     }
                   })

      post :create, params: { site_id: 'rennes', format: :json }, body: payload.to_json, as: :json

      expect(response.status).to eq 201
      expect(JSON.parse(response.body)).to include({ 'uid' => 961_722 })
      expect(response.location).to eq 'http://api-in.local/sites/rennes/jobs/961722'
    end
  end # describe "POST /sites/{{site_id}}/jobs"

  describe 'DELETE /sites/{{site_id}}/jobs/{{id}}' do
    before do
      @job = OAR::Job.first
      @expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs/#{@job.uid}.json"
      @expected_headers = {
        'Accept' => api_media_type(:json),
        'X-Remote-Ident' => @job.user,
        'X-Api-User-Cn' => @job.user
      }
    end

    it 'should return 403 if the user is not authenticated' do
      authenticate_as('')
      delete :destroy, params: { site_id: 'rennes', id: @job.uid, format: :json }
      expect(response.status).to eq 403
      expect(response.body).to eq 'You are not authorized to access this resource'
    end

    it 'should return 404 if the job does not exist' do
      authenticate_as('crohr')
      delete :destroy, params: { site_id: 'rennes', id: 'doesnotexist', format: :json }
      expect(response.status).to eq 404
      expect(response.body).to eq "Couldn't find OAR::Job with 'job_id'=doesnotexist"
    end

    it 'should return 403 if the requester does not own the job' do
      authenticate_as(@job.user + 'whatever')
      delete :destroy, params: { site_id: 'rennes', id: @job.uid, format: :json }
      expect(response.status).to eq 403
      expect(response.body).to eq 'You are not authorized to access this resource'
    end

    it 'should return 404 if the OAR api returns 404' do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url)
        .with(headers: @expected_headers)
        .to_return(
          status: 404, body: 'not found'
        )
      delete :destroy, params: { site_id: 'rennes', id: @job.uid, format: :json }
      expect(response.status).to eq 404
      expect(response.body).to eq 'Cannot find job#374172 on the OAR server'
    end

    it 'should fail if the OAR api does not return 200, 202 or 204' do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url)
        .with(headers: @expected_headers)
        .to_return(
          headers: { 'Location' => @expected_url },
          status: [400, 'Bad Request'], body: 'some error'
        )

      delete :destroy, params: { site_id: 'rennes', id: @job.uid, format: :json }
      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{@expected_url} failed with status 400: some error"
    end

    it 'should return 202, and the Location header if successful' do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url)
        .with(headers: @expected_headers)
        .to_return(
          status: 202, body: fixture('oarapi-deleted-job.json')
        )

      delete :destroy, params: { site_id: 'rennes', id: @job.uid, format: :json }
      expect(response.status).to eq 202
      expect(response.body).to be_empty
      expect(response.location).to eq "http://api-in.local/sites/rennes/jobs/#{@job.uid}"
      expect(response.headers['X-Oar-Info']).to match(/Deleting the job/)
      expect(response.content_length).to be nil
    end
  end # describe "DELETE /sites/{{site_id}}/jobs/{{id}}"
end
