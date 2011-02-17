require 'spec_helper'

describe SitesController do
  render_views
  
  describe "GET /sites" do
    it "should get the correct collection of sites" do
      EM.synchrony do
        get :index, :format => :json
        response.status.should == 200
        json['total'].should == 3
        json['items'].length.should == 3
        json['items'][0]['uid'].should == 'bordeaux'
        json['items'][0]['links'].length.should == 9
        EM.stop
      end
    end
    
    it "should correctly set the URIs when X-Api-Path-Prefix is present" do
      EM.synchrony do
        @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
        get :index, :format => :json
        response.status.should == 200
        json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/sid/sites"
        EM.stop
      end
    end
    
    it "should correctly set the URIs when X-Api-Mount-Path is present" do
      EM.synchrony do
        @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
        get :index, :format => :json
        response.status.should == 200
        json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/"
        EM.stop
      end
    end
    
    it "should correctly set the URIs when X-Api-Mount-Path and X-Api-Path-Prefix are present" do
      EM.synchrony do
        @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
        @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
        get :index, :format => :json
        response.status.should == 200
        json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/sid"
        EM.stop
      end
    end

  end # describe "GET /sites"
  
  describe "GET /sites/{{site_id}}" do
    it "should fail if the site does not exist" do
      EM.synchrony do
        get :show, :id => "doesnotexist", :format => :json
        response.status.should == 404
        EM.stop
      end
    end
    
    it "should return the site" do
      EM.synchrony do
        get :show, :id => "rennes", :format => :json
        response.status.should == 200
        json['uid'].should == 'rennes'
        json['links'].map{|l| l['rel']}.sort.should == ["clusters", "deployments", "environments", "jobs", "metrics", "parent", "self", "status", "versions"]
        json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/sites/rennes"
        EM.stop
      end
    end
  end # describe "GET /sites/{{site_id}}"
  
  
  describe "GET /sites/{{site_id}}/status" do
    it "should fail if the list of valid clusters cannot be fetched" do
      EM.synchrony do
        expected_url = "http://api-out.local:80/sites/rennes/clusters?branch=testing"
        stub_request(:get, expected_url).
          with(
            :headers => {'Accept' => media_type(:json_collection)}
          ).
          to_return(
            :status => 400, 
            :body => "some error"
          )
        get :status, :branch => 'testing', :id => "rennes", :format => :json
        response.status.should == 500
        json['code'].should == 500
        json['message'].should == "Request to #{expected_url} failed with status 400"
        EM.stop
      end
    end
    it "should return 200 and the site status" do
      EM.synchrony do
        expected_url = "http://api-out.local:80/sites/rennes/clusters?branch=master"
        stub_request(:get, expected_url).
          with(
            :headers => {'Accept' => media_type(:json_collection)}
          ).
          to_return(:body => fixture("grid5000-rennes-clusters.json"))
        get :status, :id => "rennes", :format => :json
        response.status.should == 200
        
        json['nodes'].length.should == 162
        json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort.should == [
          'paradent',
          'paramount',
          'parapide',
          'parapluie'
        ]
        
        expected_statuses = {}

        OAR::Resource.all.each{|resource|
          state = resource.state.downcase
          expected_statuses[resource.network_address] ||= {
            :hard => state,
            :soft => (state == "dead" ? "unknown" : "free"),
            :reservations => []
          }
        }
        
        fixture('grid5000-rennes-status').
          split("\n").reject{|line| line[0] == "#" || line =~ /^\s*$/}.
          uniq.map{|line| line.split(/\s/)}.
          each {|(job_id,job_queue,job_state,node,node_state)|
            if job_state =~ /running/i
              expected_statuses[node][:soft] = (job_queue == "besteffort" ? "besteffort" : "busy")
            end
            expected_statuses[node][:reservations].push(job_id.to_i)
          }

        json['nodes'].each do |node, status|
          expected_status = expected_statuses[node]
          expected_jobs = expected_status[:reservations].sort
          reservations = status["reservations"].map{|r| r["uid"]}.sort
          reservations.should == expected_jobs
          status["soft"].should == expected_status[:soft]
          status["hard"].should == expected_status[:hard]
        end
        
        EM.stop
      end
    end
    # it "should fail if the site does not exist" do
    #   pending "this will be taken care of at the api-proxy layer"
    # end
  end # "GET /sites/{{site_id}}/status"
  
end
