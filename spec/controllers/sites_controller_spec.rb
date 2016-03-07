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

  describe "GET /sites" do
    it "should get the correct collection of sites" do
      get :index, :format => :json
      response.status.should == 200
      json['total'].should == 4
      json['items'].length.should == 4
      json['items'][0]['uid'].should == 'bordeaux'
      json['items'][0]['links'].should be_a(Array)
    end

    it "should correctly set the URIs when X-Api-Path-Prefix is present" do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      get :index, :format => :json
      response.status.should == 200
      json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/sid/sites"
    end

    it "should correctly set the URIs when X-Api-Mount-Path is present" do
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, :format => :json
      response.status.should == 200
      json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/"
    end

    it "should correctly set the URIs when X-Api-Mount-Path and X-Api-Path-Prefix are present" do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, :format => :json
      response.status.should == 200
      json['links'].find{|l| l['rel'] == 'self'}['href'].should == "/sid"
    end

  end # describe "GET /sites"

  describe "GET /sites/{{site_id}}" do
    it "should fail if the site does not exist" do
      get :show, :id => "doesnotexist", :format => :json
      response.status.should == 404
    end

    it "should return the site" do      
      get :show, :id => "rennes", :format => :json
      response.status.should == 200
      assert_expires_in(60, :public => true)
      json['uid'].should == 'rennes'
      json['links'].map{|l| l['rel']}.sort.should == [
        "clusters",
        "deployments",
        "environments",
        "jobs",
        "metrics",
        "parent",
        "self",
        "status",
        "version",
        "versions",
        "vlans"
      ]
      json['links'].find{|l|
        l['rel'] == 'self'
      }['href'].should == "/sites/rennes"
      json['links'].find{|l|
        l['rel'] == 'clusters'
      }['href'].should == "/sites/rennes/clusters"
      json['links'].find{|l|
        l['rel'] == 'version'
      # abasu - 03.03.2016 - updated value from 070663579dafada27e078f468614f85a62cf2992
      }['href'].should == "/sites/rennes/versions/d03a97ebe1fcf3b9f10cf4eb066a1b97ddd4e09a"
    end
    
    it "should return subresource links that are only in testing branch" do
      get :show, :id => "lille", :format => :json, :branch => "testing"
      response.status.should == 200
      json['links'].map{|l| l['rel']}.sort.should == [
        "clusters",
        "deployments",
        "environments",
        "jobs",
        "metrics",
        "network_equipments",
        "parent",
        "self",
        "status",
        "version",
        "versions",
        "vlans"
      ]
    end
    
    it "should return the specified version, and the max-age value in the Cache-Control header should be big" do
      get :show, :id => "rennes", :format => :json, :version => "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      response.status.should == 200
      assert_expires_in(24*3600*30, :public => true)
      json['uid'].should == 'rennes'
      json['version'].should == 'b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4'
      json['links'].find{|l|
        l['rel'] == 'version'
      }['href'].should == "/sites/rennes/versions/b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
    end
  end # describe "GET /sites/{{site_id}}"


  describe "GET /sites/{{site_id}}/status" do
    it "should fail if the list of valid clusters cannot be fetched" do      
      expected_url = "http://api-out.local:80/sites/rennes/clusters?branch=testing"
      stub_request(:get, expected_url).
        with(
          :headers => {'Accept' => media_type(:json)}
        ).
        to_return(
          :status => 400,
          :body => "some error"
        )
      get :status, :branch => 'testing', :id => "rennes", :format => :json
      response.status.should == 400
      response.body.should == "Request to #{expected_url} failed with status 400: some error"
    end
    it "should return 200 and the site status" do
      expected_url = "http://api-out.local:80/sites/rennes/clusters?branch=master"
      stub_request(:get, expected_url).
        with(
          :headers => {'Accept' => media_type(:json)}
        ).
        to_return(:body => fixture("grid5000-rennes-clusters.json"))
      get :status, :id => "rennes", :format => :json
      response.status.should == 200

      json['nodes'].length.should == 168
      json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort.should == [
        'paradent',
        'paramount',
        'parapide',
        'parapluie'
      ]
    end
    # it "should fail if the site does not exist" do
    #   pending "this will be taken care of at the api-proxy layer"
    # end
  end # "GET /sites/{{site_id}}/status"

end
