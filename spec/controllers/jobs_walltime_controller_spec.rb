# Copyright (c) 2022 Samir Noir, INRIA Grenoble - Rhône-Alpes
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

describe JobsWalltimeController do
  render_views
  before do
    @base_expected_uri = 'http://api-out.local/sites/grenoble/internal/oarapi/'
    @headers = { 'Content-Type' => 'application/json' }
  end

  describe 'GET /sites/{{site_id}}/jobs/{{id}}/walltime' do
    it 'should fetch the walltime status for job' do
      stub_request(:get, File.join(@base_expected_uri, 'jobs/1234/details.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 200, body: fixture('oarapi-grenoble-job_1234.json'), headers: {})

      authenticate_as('snoir')
      get :show, params: {
        site_id: 'grenoble',
        id: 1234,
        headers: { 'Content-Type' => 'application/json' }
      }
      expect(response.status).to eq 200
      expect(json.length).to eq 12
      expect(json['uid']).to eq 1234
      expect(json['delay_next_jobs']).to eq 'FORBIDDEN'
      expect(json['walltime']).to eq '1:0:0'
      expect(json['links']).to eq [
        {
          'rel'  => 'self',
          'href' => '/sites/grenoble/jobs/1234/walltime',
          'type' => 'application/vnd.grid5000.item+json'
        },
        {
          'rel'  => 'parent',
          'href' => '/sites/grenoble/jobs/1234',
          'type' => 'application/vnd.grid5000.item+json'
        }
      ]
    end

    it 'should return 404 for unknown job' do
      stub_request(:get, File.join(@base_expected_uri, 'jobs/341200000/details.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 404, body: "", headers: {})

      authenticate_as('snoir')
      get :show, params: {
        site_id: 'grenoble',
        id: 341200000,
      }
      expect(response.status).to eq 404
      expect(response.body).to eq "Job id '341200000' cannot be found."
    end
  end

  describe 'POST /sites/{{site_id}}/jobs/{{id}}/walltime' do
    it 'should return 202 when walltime change request is accepted' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/1234.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 202, body: fixture('oarapi-grenoble-job_1234-accepted.json'), headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 1234 },
        body: { walltime: '+01h' }.to_json, as: :json
      expect(response.status).to eq 202
      expect(response.body).to eq 'Walltime change request updated for job 1234, it will be handled shortly'
      expect(response.location).to eq 'http://api-in.local/sites/grenoble/jobs/1234/walltime'
    end

    it 'should return 404 for unknown job' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/341200000.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 404, body: "", headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 341200000 },
        body: { walltime: '+01' }.to_json, as: :json
      expect(response.status).to eq 404
      expect(response.body).to eq "Job id '341200000' cannot be found."
    end

    it 'should return 403 for other user job' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/3456.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 403, body: fixture('oarapi-grenoble-job_3456.json'), headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 3456 },
        body: { walltime: '+01' }.to_json, as: :json
      expect(response.status).to eq 403
      expect(response.body).to eq 'Job 3456 does not belong to you'
    end

    it 'should return 403 for not running job' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/4567.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 403, body: fixture('oarapi-grenoble-job_4567.json'), headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 4567 },
        body: { walltime: '+01' }.to_json, as: :json
      expect(response.status).to eq 403
      expect(response.body).to eq 'Job 4567 is not running'
    end

    # Here test with 'force' but could also be 'delay_next_jobs'
    it 'should return 403 when using a parameter disabled in OAR' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/1234.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 403, body: fixture('oarapi-grenoble-job_1234-force.json'), headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 1234 },
        body: { walltime: '+01' }.to_json, as: :json
      expect(response.status).to eq 403
      expect(response.body).to eq 'Walltime change for this job is not allowed to be forced'
    end

    it 'should return 400 when walltime is missing from payload' do
      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 3456 },
        body: { force: true }.to_json, as: :json
      expect(response.status).to eq 400
      expect(response.body).to eq 'The job walltime change you are trying to submit is not valid: ' \
                                  'you must give a new walltime'
    end

    Grid5000::JobWalltime::YES_NO_ATTRIBUTES.each do |attr|
      it "should return 400 when #{attr} is not a boolean" do
        authenticate_as('snoir')
        post :update, params: { site_id: 'grenoble', id: 3456 },
          body: { walltime: '+01h', attr => 1 }.to_json, as: :json
        expect(response.status).to eq 400
        expect(response.body).to eq "The job walltime change you are trying to submit is not valid: " \
                                    "delay_next_jobs, force, whole must be a Boolean"
      end
    end

    it 'should return 415 when changing walltime with a wrong Content-Type' do
      stub_request(:post, File.join(@base_expected_uri, 'jobs/1234.json')).
        with(
          headers: {
            'Host'=>'api-out.local',
          }).
          to_return(status: 202, body: fixture('oarapi-grenoble-job_1234-accepted.json'), headers: {})

      authenticate_as('snoir')
      post :update, params: { site_id: 'grenoble', id: 1234}, body: { walltime: '+01h' }.to_json
      expect(response.status).to eq 415
      expect(response.body).to eq "Content-Type 'application/x-www-form-urlencoded' is not supported"
    end
  end
end
