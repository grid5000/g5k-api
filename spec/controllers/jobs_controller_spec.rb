require 'spec_helper'

describe JobsController do
  render_views
  before do
    @job_uids = [374191, 374190, 374189, 374188, 374187, 374185, 374186, 374184, 374183, 374182, 374181, 374180, 374179, 374178, 374177, 374176, 374175, 374174, 374173, 374172]
  end
  
  describe "GET /sites/{{site_id}}/jobs" do
    it "should fetch the list of jobs, with their links" do
      EM.synchrony do
        get :index, :site_id => "rennes", :format => :json
        response.status.should == 200
        json['total'].should == @job_uids.length
        json['offset'].should == 0
        json['items'].length.should == 20
        json['items'].map{|i| i['uid']}.should == @job_uids
        json['items'].all?{|i| i.has_key?('links')}.should be_true
        json['items'][0]['links'].should == [
          {
            "rel"=> "self", 
            "href"=> "/sites/rennes/jobs/374191", 
            "type"=> media_type(:json)
          }, 
          {
            "rel"=> "parent", 
            "href"=> "/sites/rennes", 
            "type"=> media_type(:json)
          }
        ]
        json['links'].should == [
          {
            "rel"=>"self", 
            "href"=>"/sites/rennes/jobs", 
            "type"=>media_type(:json_collection)
          }, 
          {
            "rel"=>"parent", 
            "href"=>"/sites/rennes", 
            "type"=>media_type(:json)
          }
        ]
        EM.stop
      end
    end
    it "should correctly deal with pagination filters" do
      EM.synchrony do
        get :index, :site_id => "rennes", :offset => 10, :limit => 5, :format => :json
        response.status.should == 200
        json['total'].should == @job_uids.length
        json['offset'].should == 10
        json['items'].length.should == 5
        json['items'].map{|i| i['uid']}.should == @job_uids.slice(10,5)
        EM.stop
      end
    end
  end # describe "GET /sites/{{site_id}}/jobs"
  
  describe "GET /sites/{{site_id}}/jobs/{{id}}" do
    it "should return 404 if the job does not exist" do
      EM.synchrony do
        get :show, :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find OAR::Job with ID=doesnotexist"
        EM.stop
      end
    end
    it "should return 200 and the job" do
      EM.synchrony do
        get :show, :site_id => "rennes", :id => @job_uids[0], :format => :json
        response.status.should == 200
        json["uid"].should == @job_uids[0]
        json["links"].should be_a(Array)
        json.keys.sort.should == ["assigned_nodes", "command", "directory", "events", "links", "message", "mode", "project", "properties", "queue", "resources_by_type", "scheduled_at", "started_at", "state", "submitted_at", "types", "uid", "user", "user_uid", "walltime"]
        json['types'].should == ['deploy']
        json['scheduled_at'].should == 1294395995
        EM.stop
      end
    end
  end # describe "GET /sites/{{site_id}}/jobs/{{id}}"
  
  describe "POST /sites/{{site_id}}/jobs" do
    before do
      @valid_job_attributes = {"command" => "sleep 3600"}
    end
    it "should return 403 if the user is not authenticated" do
      EM.synchrony do
        authenticate_as("")
        post :create, :site_id => "rennes", :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    it "should fail if the OAR api does not return 201 or 202" do
      EM.synchrony do
        payload = @valid_job_attributes
        authenticate_as("crohr")
        send_payload(payload, :json)
        
        expected_url = "http://api-out.local:80/sites/rennes/internal/oarapi/jobs.json"
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
        response.status.should == 500
        json['message'].should == "Request to #{expected_url} failed with status 400"
        EM.stop
      end
    end
    
    it "should return 201, and the Location header" do
      EM.synchrony do
        payload = @valid_job_attributes
        authenticate_as("crohr")
        send_payload(payload, :json)
        
        expected_url = "http://api-out.local:80/sites/rennes/internal/oarapi/jobs.json"
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
            :status => 201,
            :body => fixture("oarapi-submitted-job.json")
          )
        
        post :create, :site_id => "rennes", :format => :json
        response.status.should == 201
        response.body.should be_empty
        response.location.should == "http://api-in.local/sites/rennes/jobs/961722"
        response.content_length.should be_nil
        EM.stop
      end
    end
  end # describe "POST /sites/{{site_id}}/jobs"
  
  
  describe "DELETE /sites/{{site_id}}/jobs/{{id}}" do
    before do
      @job = OAR::Job.first
      @expected_url = "http://api-out.local:80/sites/rennes/internal/oarapi/jobs/#{@job.uid}.json"
      @expected_headers = {
        'Accept' => media_type(:json), 
        'X-Remote-Ident' => @job.user
      }
    end
    
    it "should return 403 if the user is not authenticated" do
      EM.synchrony do
        authenticate_as("")
        delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    
    it "should return 404 if the job does not exist" do
      EM.synchrony do
        authenticate_as("crohr")
        delete :destroy, :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find OAR::Job with ID=doesnotexist"
        EM.stop
      end
    end
    
    it "should return 403 if the requester does not own the job" do
      EM.synchrony do
        authenticate_as(@job.user+"whatever")
        delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    
    it "should return 404 if the OAR api returns 404" do
      EM.synchrony do
        authenticate_as(@job.user)
        stub_request(:delete, @expected_url).
          with(:headers => @expected_headers).
          to_return(
            :status => 404, :body => "not found"
          )
        delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
        response.status.should == 404
        json['message'].should == "Cannot find job#374172 on the OAR server"
        EM.stop
      end
    end
    
    it "should fail if the OAR api does not return 200, 202 or 204" do
      EM.synchrony do
        authenticate_as(@job.user)
        stub_request(:delete, @expected_url).
          with(:headers => @expected_headers).
          to_return(
            :status => 400, :body => "some error"
          )
        
        delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
        response.status.should == 500
        json['message'].should == "Request to #{@expected_url} failed with status 400"
        EM.stop
      end
    end
    
    it "should return 202, and the Location header if successful" do
      EM.synchrony do
        authenticate_as(@job.user)
        stub_request(:delete, @expected_url).
          with(:headers => @expected_headers).
          to_return(
            :status => 202, :body => fixture("oarapi-deleted-job.json")
          )
        
        delete :destroy, :site_id => "rennes", :id => @job.uid, :format => :json
        response.status.should == 202
        response.body.should be_empty
        response.location.should == "http://api-in.local/sites/rennes/jobs/#{@job.uid}"
        response.headers['X-Oar-Info'].should =~ /Deleting the job/
        response.content_length.should be_nil
        EM.stop
      end
    end
  end # describe "DELETE /sites/{{site_id}}/jobs/{{id}}"
end
