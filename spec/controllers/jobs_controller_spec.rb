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
    @job_uids = [374196, 374195, 374194, 374193, 374192, 374191, 374190, 374189, 374188, 374187, 374185, 374186, 374184, 374183, 374182, 374181, 374180, 374179, 374178, 374177, 374176, 374175, 374174, 374173, 374172, 374197, 374198, 374199, 374205, 374210]
  end

  describe "GET /sites/{{site_id}}/jobs" do
    it "should fetch the list of jobs, with their links" do
      get :index, :site_id => "rennes", :format => :json
      expect(response.status).to eq 200
      expect(json['total']).to eq @job_uids.length
      expect(json['offset']).to eq 0
      expect(json['items'].length).to eq @job_uids.length
      expect(json['items'].map{|i| i['uid']}.sort).to eq @job_uids.sort
      expect(json['items'].all?{|i| i.has_key?('links')}).to be true
      expect(json['items'][0]['links']).to eq ([
        {
          "rel"=> "self",
          "href"=> "/sites/rennes/jobs/374210",
          "type"=> media_type(:g5kitemjson)
        },
        {
          "rel"=> "parent",
          "href"=> "/sites/rennes",
          "type"=> media_type(:g5kitemjson)
        }
      ])
      expect(json['links']).to eq ([
        {
          "rel"=>"self",
          "href"=>"/sites/rennes/jobs",
          "type"=>media_type(:g5kcollectionjson)
        },
        {
          "rel"=>"parent",
          "href"=>"/sites/rennes",
          "type"=>media_type(:g5kitemjson)
        }
      ])
    end
    it "should correctly deal with pagination filters" do
      get :index, :site_id => "rennes", :offset => 11, :limit => 5, :format => :json
      expect(response.status).to eq 200
      expect(json['total']).to eq @job_uids.length
      expect(json['offset']).to eq 11
      expect(json['items'].length).to eq 5
      expect(json['items'].map{|i| i['uid']}).to eq ([374190, 374189, 374188, 374187, 374186])
    end
    it "should correctly deal with other filters" do
      params = {:user => 'crohr', :name => 'whatever'}
      expect(OAR::Job).to receive(:list).with(hash_including(params)).
        and_return(OAR::Job.limit(5))
      get :index, params.merge(:site_id => "rennes", :format => :json)
      expect(response.status).to eq 200
    end
  end # describe "GET /sites/{{site_id}}/jobs"

  describe "GET /sites/{{site_id}}/jobs/{{id}}" do
    it "should return 404 if the job does not exist" do
      get :show, :site_id => "rennes", :id => "doesnotexist", :format => :json
      expect(response.status).to eq 404
      expect(response.body).to eq "Couldn't find OAR::Job with 'job_id'=doesnotexist"
    end
    it "should return 200 and the job" do
      get :show, :site_id => "rennes", :id => @job_uids[5], :format => :json
      expect(response.status).to eq 200
      expect(json["uid"]).to eq @job_uids[5]
      expect(json["links"]).to be_a(Array)
      expect(json.keys.sort).to eq (["assigned_nodes", "command", "directory", "events", "links", "message", "mode", "project", "properties", "queue", "resources_by_type", "scheduled_at", "started_at", "state", "submitted_at", "types", "uid", "user", "user_uid", "walltime"])
      expect(json['types']).to eq (['deploy'])
      expect(json['scheduled_at']).to eq 1294395995
      expect(json['assigned_nodes'].sort).to eq (["paramount-4.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr"].sort)
      expect(json['resources_by_type']["cores"].sort).to eq (["paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr"].sort)
    end
  end # describe "GET /sites/{{site_id}}/jobs/{{id}}"

  describe "POST /sites/{{site_id}}/jobs" do
    before do
      @valid_job_attributes = {"command" => "sleep 3600"}
    end
    after do
      begin
        OAR::Job.find(961722).delete
      rescue Exception => e
      end
    end
    it "should return 403 if the user is not authenticated" do
      authenticate_as("")
      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 403
      expect(response.body).to eq "You are not authorized to access this resource"
    end
    it "should return 403 if the user is anonymous" do
      authenticate_as("anonymous")
      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 403
      expect(response.body).to eq "You are not authorized to access this resource"
    end
    it "should fail if the OAR api does not return 201, 202 or 400" do
      payload = @valid_job_attributes
      authenticate_as("crohr")
      send_payload(payload, :json)

      expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs.json"
      stub_request(:post, expected_url).
        with(
          :headers => {
            'Accept' => media_type(:json),
            'Content-Type' => media_type(:json),
            'X-Remote-Ident' => "crohr"
          },
          :body => Grid5000::Job.new(payload).to_hash(:destination => "oar-2.4-submission").to_json
        ).
        to_return(
          :status => 400,
          :body => "some error"
        )

      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{expected_url} failed with status 400: some error"
    end
  # abasu : unit test for bug ref 5912 to handle error codes - 02.04.2015
    it "should return a 400 error if the OAR API returns 400 error code" do
      payload = @valid_job_attributes.merge("resources" => "{ib30g='YES'}/nodes=2")
      authenticate_as("crohr")
      send_payload(payload, :json)

      expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs.json"
      stub_request(:post, expected_url).
        with(
          :headers => {
            'Accept' => media_type(:json),
            'Content-Type' => media_type(:json),
            'X-Remote-Ident' => "crohr"
          },
          :body => Grid5000::Job.new(payload).to_hash(:destination => "oar-2.4-submission").to_json
        ).
        to_return(
          :status => 400,
          :body => "Bad Request"
        )

      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{expected_url} failed with status 400: Bad Request"
    end # "should return a 400 error if the OAR API returns 400 error code"
  # abasu : unit test for bug ref 5912 to handle error codes - 02.04.2015
    it "should return a 401 error if the OAR API returns 401 error code" do
      payload = @valid_job_attributes
      authenticate_as("xyz")
      send_payload(payload, :json)

      expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs.json"
      stub_request(:post, expected_url).
        with(
          :headers => {
            'Accept' => media_type(:json),
            'Content-Type' => media_type(:json),
            'X-Remote-Ident' => "xyz"
          },
          :body => Grid5000::Job.new(payload).to_hash(:destination => "oar-2.4-submission").to_json
        ).
        to_return(
          :status => 401,
          :body => "Authorization Required"
        )

      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 401
      expect(response.body).to eq "Request to #{expected_url} failed with status 401: Authorization Required"
    end # "should return a 401 error if the OAR API returns 400 error code"
    it "should return 201, the job details, and the Location header" do
      payload = @valid_job_attributes
      authenticate_as("crohr")
      send_payload(payload, :json)

      expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs.json"
      stub_request(:post, expected_url).
        with(
          :headers => {
            'Accept' => media_type(:json),
            'Content-Type' => media_type(:json),
            'X-Remote-Ident' => "crohr"
          },
          :body => Grid5000::Job.new(payload).to_hash(:destination => "oar-2.4-submission").to_json
        ).
        to_return ( lambda { |request|
                      # use a side_effect to really test active_record finders
                      create(:job, job_id: 961722)
                      {
                        :status => 201,
                        :body => fixture("oarapi-submitted-job.json")
                      }
                    }
                  )

      post :create, :site_id => "rennes", :format => :json
      expect(response.status).to eq 201
      expect(JSON.parse(response.body)).to include ({"uid" => 961722})
      expect(response.location).to eq "http://api-in.local/sites/rennes/jobs/961722"
    end
  end # describe "POST /sites/{{site_id}}/jobs"


  describe "DELETE /sites/{{site_id}}/jobs/{{id}}" do
    before do
      @job = OAR::Job.first
      @expected_url = "http://api-out.local/sites/rennes/internal/oarapi/jobs/#{@job.uid}.json"
      @expected_headers = {
        'Accept' => media_type(:json),
        'X-Remote-Ident' => @job.user
      }
    end

    it "should return 403 if the user is not authenticated" do
      authenticate_as("")
      delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
      expect(response.status).to eq 403
      expect(response.body).to eq "You are not authorized to access this resource"
    end

    it "should return 404 if the job does not exist" do
      authenticate_as("crohr")
      delete :destroy, :site_id => "rennes", :id => "doesnotexist", :format => :json
      expect(response.status).to eq 404
      expect(response.body).to eq "Couldn't find OAR::Job with 'job_id'=doesnotexist"
    end

    it "should return 403 if the requester does not own the job" do
      authenticate_as(@job.user+"whatever")
      delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
      expect(response.status).to eq 403
      expect(response.body).to eq "You are not authorized to access this resource"
    end

    it "should return 404 if the OAR api returns 404" do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url).
        with(:headers => @expected_headers).
        to_return(
          :status => 404, :body => "not found"
        )
      delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
      expect(response.status).to eq 404
      expect(response.body).to eq "Cannot find job#374172 on the OAR server"
    end

    it "should fail if the OAR api does not return 200, 202 or 204" do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url).
        with(:headers => @expected_headers).
        to_return(
          :status => 400, :body => "some error"
        )

      delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
      expect(response.status).to eq 400
      expect(response.body).to eq "Request to #{@expected_url} failed with status 400: some error"
    end

    it "should return 202, and the Location header if successful" do
      authenticate_as(@job.user)
      stub_request(:delete, @expected_url).
        with(:headers => @expected_headers).
        to_return(
          :status => 202, :body => fixture("oarapi-deleted-job.json")
        )

      delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
      expect(response.status).to eq 202
      expect(response.body).to be_empty
      expect(response.location).to eq "http://api-in.local/sites/rennes/jobs/#{@job.uid}"
      expect(response.headers['X-Oar-Info']).to match(/Deleting the job/)
      expect(response.content_length).to be nil
    end
  end # describe "DELETE /sites/{{site_id}}/jobs/{{id}}"
end
