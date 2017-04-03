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
        "deployment", # abasu 19.10.2016 - bug #7364 changed "deployments" to "deployment"
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
      }['href'].should == "/sites/rennes/versions/2ed3470e0881a22baa43718e62098a0b8dee1e4b"
    end
    
    it "should return subresource links that are only in testing branch" do
      get :show, :id => "lille", :format => :json, :branch => "testing"
      response.status.should == 200
      json['links'].map{|l| l['rel']}.sort.should == [
        "clusters",
        "deployment", # abasu 19.10.2016 - bug #7364 changed "deployments" to "deployment"
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
    
    # abasu 19.10.2016 - bug #7364 changed "deployments" to "deployment"
    it "should return link for deployment" do
      get :show, :id => "rennes", :format => :json
      response.status.should == 200
      json['uid'].should == 'rennes'
      json['links'].find{|l|
        l['rel'] == 'deployment'
      }['href'].should == "/sites/rennes/deployment"
    end # it "should return link for deployment" do
    
    # abasu 26.10.2016 - bug #7301 should return link /servers if present in site
    it "should return link /servers if present in site" do
      get :show, :id => "nancy", :format => :json
      response.status.should == 200
      json['uid'].should == 'nancy'
      json['links'].find{|l|
        l['rel'] == 'servers'
      }['href'].should == "/sites/nancy/servers"
    end # it "should return link /servers if present in site" do
    
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
    it "should return 200 and the site status" do
      get :status, :id => "rennes", :format => :json
      response.status.should == 200

      json['nodes'].length.should == 196
      json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort.should == [
        'paraquad',
        'paramount',
        'paravent'
      ].sort
    end
    # it "should fail if the site does not exist" do
    #   pending "this will be taken care of at the api-proxy layer"
    # end
  end # "GET /sites/{{site_id}}/status"

end
