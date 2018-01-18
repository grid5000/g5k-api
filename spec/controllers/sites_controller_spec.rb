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
      expect(response.status).to eq 200
      expect(json['total']).to eq 4
      expect(json['items'].length).to eq 4
      expect(json['items'][0]['uid']).to eq 'bordeaux'
      expect(json['items'][0]['links']).to be_a(Array)
    end

    it "should correctly set the URIs when X-Api-Path-Prefix is present" do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['links'].find{|l| l['rel'] == 'self'}['href']).to eq "/sid/sites"
    end

    it "should correctly set the URIs when X-Api-Mount-Path is present" do
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['links'].find{|l| l['rel'] == 'self'}['href']).to eq "/"
    end

    it "should correctly set the URIs when X-Api-Mount-Path and X-Api-Path-Prefix are present" do
      @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
      @request.env['HTTP_X_API_MOUNT_PATH'] = '/sites'
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['links'].find{|l| l['rel'] == 'self'}['href']).to eq "/sid"
    end

  end # describe "GET /sites"

  describe "GET /sites/{{site_id}}" do
    it "should fail if the site does not exist" do
      get :show, :id => "doesnotexist", :format => :json
      expect(response.status).to eq 404
    end

    it "should return the site" do      
      get :show, :id => "rennes", :format => :json
      expect(response.status).to eq 200
      assert_expires_in(60, :public => true)
      expect(json['uid']).to eq 'rennes'
      expect(json['links'].map{|l| l['rel']}.sort).to eq [
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
      expect(json['links'].find{|l|
        l['rel'] == 'self'
      }['href']).to eq "/sites/rennes"
      expect(json['links'].find{|l|
        l['rel'] == 'clusters'
      }['href']).to eq "/sites/rennes/clusters"
      expect(json['links'].find{|l|
        l['rel'] == 'version'
      }['href']).to eq "/sites/rennes/versions/8a562420c9a659256eeaafcfd89dfa917b5fb4d0"
    end
    
    it "should return subresource links that are only in testing branch" do
      get :show, :id => "lille", :format => :json, :branch => "testing"
      expect(response.status).to eq 200
      expect(json['links'].map{|l| l['rel']}.sort).to eq [
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
    
    # abasu 19.10.2016 - bug #7364 changed "deployments" to "deployment"
    it "should return link for deployment" do
      get :show, :id => "rennes", :format => :json
      expect(response.status).to eq 200
      expect(json['uid']).to eq 'rennes'
      expect(json['links'].find{|l|
        l['rel'] == 'deployments'
      }['href']).to eq "/sites/rennes/deployments"
    end # it "should return link for deployment" do
    
    # abasu 26.10.2016 - bug #7301 should return link /servers if present in site
    it "should return link /servers if present in site" do
      get :show, :id => "nancy", :format => :json
      expect(response.status).to eq 200
      expect(json['uid']).to eq 'nancy'
      expect(json['links'].find{|l|
        l['rel'] == 'servers'
      }['href']).to eq "/sites/nancy/servers"
    end # it "should return link /servers if present in site" do

    it "should return the specified version, and the max-age value in the Cache-Control header should be big" do
      get :show, :id => "rennes", :format => :json, :version => "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      expect(response.status).to eq 200
      assert_expires_in(24*3600*30, :public => true)
      expect(json['uid']).to eq 'rennes'
      expect(json['version']).to eq 'b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4'
      expect(json['links'].find{|l|
        l['rel'] == 'version'
      }['href']).to eq "/sites/rennes/versions/b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
    end
  end # describe "GET /sites/{{site_id}}"


  describe "GET /sites/{{site_id}}/status" do
    it "should return 200 and the site status" do
      get :status, :id => "rennes", :format => :json
      expect(response.status).to eq 200
      expect(json['nodes'].length).to eq 196
      expect(json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort).to eq [
        'paraquad',
        'paramount',
        'paravent'
      ].sort
      expect(json['disks']).to be_empty # no reservable disks on paramount-4
      expect(json['nodes']['paramount-4.rennes.grid5000.fr']['reservations']).not_to be_nil
    end

    # GET /sites/{{site_id}}/status?network_address={{network_address}}
    it "should return the status ONLY for the specified node" do      
      get :status, :id => "rennes", :network_address => "paramount-4.rennes.grid5000.fr", :format => :json
      expect(response.status).to eq 200
      expect(json['nodes'].keys.map{|k| k.split('.')[0]}.uniq.sort).to eq ['paramount-4']
      expect(json['disks']).to be_empty
      expect(json['nodes']['paramount-4.rennes.grid5000.fr']['reservations']).not_to be_nil
    end

    # it "should fail if the site does not exist" do
    #   pending "this will be taken care of at the api-proxy layer"
    # end
  end # "GET /sites/{{site_id}}/status"

end
