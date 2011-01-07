require 'spec_helper'

describe JobsController do
  render_views
  before do
    @job_uids = [374191, 374190, 374189, 374188, 374187, 374186, 374185, 374184, 374183, 374182, 374181, 374180, 374179, 374178, 374177, 374176, 374175, 374174, 374173, 374172]
  end
  
  describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/jobs" do
    it "should fetch the list of jobs, with their links" do
      EM.synchrony do
        get :index, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        response.status.should == 200
        json['total'].should == @job_uids.length
        json['offset'].should == 0
        json['items'].length.should == 20
        json['items'].map{|i| i['uid']}.should == @job_uids
        json['items'].all?{|i| i.has_key?('links')}.should be_true
        json['items'][0]['links'].should == [
          {
            "rel"=> "self", 
            "href"=> "/platforms/grid5000/sites/rennes/jobs/374191", 
            "type"=> media_type(:json)
          }, 
          {
            "rel"=> "parent", 
            "href"=> "/platforms/grid5000/sites/rennes", 
            "type"=> media_type(:json)
          }
        ]
        json['links'].should == [
          {
            "rel"=>"self", 
            "href"=>"/platforms/grid5000/sites/rennes/jobs", 
            "type"=>media_type(:json_collection)
          }, 
          {
            "rel"=>"parent", 
            "href"=>"/platforms/grid5000/sites/rennes", 
            "type"=>media_type(:json)
          }
        ]
        EM.stop
      end
    end
    it "should correctly deal with pagination filters" do
      EM.synchrony do
        get :index, :platform_id => "grid5000", :site_id => "rennes", :offset => 10, :limit => 5, :format => :json
        response.status.should == 200
        json['total'].should == @job_uids.length
        json['offset'].should == 10
        json['items'].length.should == 5
        json['items'].map{|i| i['uid']}.should == @job_uids.slice(10,5)
        EM.stop
      end
    end
  end # describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/jobs"
  
  describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/jobs/{{:id}}" do
    it "should return 404 if the job does not exist" do
      EM.synchrony do
        get :show, :platform_id => "grid5000", :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find OAR::Job with ID=doesnotexist"
        EM.stop
      end
    end
    it "should return 200 and the job" do
      EM.synchrony do
        get :show, :platform_id => "grid5000", :site_id => "rennes", :id => @job_uids[0], :format => :json
        response.status.should == 200
        json["uid"].should == @job_uids[0]
        json["links"].should be_a(Array)
        json.keys.sort.should == [
          "links", "predicted_start_time", "project", 
          "queue", "start_time", "state", "uid", 
          "user", "walltime"
        ]
        EM.stop
      end
    end
  end # describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/jobs/{{:id}}"
end
