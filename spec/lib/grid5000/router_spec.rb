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

describe Grid5000::Router do

  describe "uri_to called with default parameters (:in and :relative)" do
    it "should take into account X-Api-Version header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/sites/rennes/jobs"
    end

    it "should take into account X-Api-Path-Prefix header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_PATH_PREFIX' => 'grid5000'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/grid5000/sites/rennes/jobs"
    end

    it "should take into account X-Api-Root-Path header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'proxies/grid5000'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/proxies/grid5000/sites/rennes/jobs"
    end

    it "should take into account X-Api-Mount-Path header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => 'sites/rennes'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/jobs"
    end

    it "should only substitute X-Api-Mount-Path header at the start of url" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => '/rennes'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sites/rennes/jobs"
    end

    it "should take into account both X-Api-Version and X-Api-Path-Prefix headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'grid5000'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/grid5000/sites/rennes/jobs"
    end

    it "Should properly combine X-API-[Mount-Path,Version,Path-Prefix] headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => '/sites/rennes/',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/g5k-api/jobs"
    end

    it "Should properly combine X-API-[Root-Path,Version,Path-Prefix] headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'proxies/grid5000',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/proxies/grid5000/sid/g5k-api/sites/rennes/jobs"
    end

    it "Should properly combine all X-API headers supported" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'sites/fr/grid5000',
        'HTTP_X_API_MOUNT_PATH' => '/sites/',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api'
      })
      Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sites/fr/grid5000/sid/g5k-api/rennes/jobs"
    end
  end
  
  describe "uri_to called for absolute parameters (:in and :absolute)" do
    #used for job creation, deletion and redirect to dashboard
    before do
      @server_url="http://api-in.local"
      @proxy_header="proxy.public, proxy.local"
      @proxy_url="https://proxy.public"
      expect(Rails.my_config("base_uri_in".to_sym)).to eq @server_url
    end

    it "should take into account X-Api-Version header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/sid/sites/rennes/jobs"
    end

    it "should take into account X-Api-Path-Prefix header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_PATH_PREFIX' => 'grid5000',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/grid5000/sites/rennes/jobs"
    end

    it "should take into account X-Api-Root-Path header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'proxies/grid5000',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/proxies/grid5000/sites/rennes/jobs"
    end

    it "should take into account X-Api-Mount-Path header" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => 'sites/rennes',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/jobs"
    end

    it "should only substitute X-Api-Mount-Path header at the start of url" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => '/rennes',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/sites/rennes/jobs"
    end

    it "should take into account both X-Api-Version and X-Api-Path-Prefix headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'grid5000',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/sid/grid5000/sites/rennes/jobs"
    end

    it "Should properly combine X-API-[Mount-Path,Version,Path-Prefix] headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_MOUNT_PATH' => '/sites/rennes/',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/sid/g5k-api/jobs"
    end

    it "Should properly combine X-API-[Root-Path,Version,Path-Prefix] headers" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'proxies/grid5000',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/proxies/grid5000/sid/g5k-api/sites/rennes/jobs"
    end

    it "Should properly combine all X-API headers supported" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_ROOT_PATH' => 'sites/fr/grid5000',
        'HTTP_X_API_MOUNT_PATH' => '/sites/',
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_API_PATH_PREFIX' => 'g5k-api',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url}/sites/fr/grid5000/sid/g5k-api/rennes/jobs"
    end

    it "Should allow override of protocol" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_FORWARDED_HOST' => @proxy_header
      })
      expect(Rails).to receive(:my_config).with(:'proxy.public').twice.and_return("http")
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "#{@proxy_url.gsub!('https','http')}/sid/sites/rennes/jobs"
    end

    it "Should allow override of protocol from config file" do
      request = double(Rack::MockRequest, :env => {
        'HTTP_X_API_VERSION' => 'sid',
        'HTTP_X_FORWARDED_HOST' => "from.config, "+@proxy_header
      })
      expect(Rails.my_config(:'from.config')).to eq "http"
      expect(Grid5000::Router.uri_to(request, "/sites/rennes/jobs", :in, :absolute)).to eq "http://from.config/sid/sites/rennes/jobs"
    end
  end

  it "should take into account the parameters of the config file with empty path" do
    Rails.my_config("base_uri_out".to_sym).should == "http://api-out.local"
    request = double(Rack::MockRequest, :env => {
      'HTTP_X_API_VERSION' => 'sid'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/internal/oarapi/jobs/374172.json", :out).should ==  "http://api-out.local/sid/sites/rennes/internal/oarapi/jobs/374172.json"
  end

  it "should take into account the parameters of the config file with path (for dev environment)" do
    Api::Application::CONFIG["base_uri_out"] = "http://api-out.local/sid"
    Rails.my_config("base_uri_out".to_sym).should == "http://api-out.local/sid"
    request = double(Rack::MockRequest, :env => {})
    Grid5000::Router.uri_to(request, "/sites/rennes/internal/oarapi/jobs/374172.json", :out).should ==  "http://api-out.local/sid/sites/rennes/internal/oarapi/jobs/374172.json"
  end	

  it "should take into account tls options" do
    Api::Application::CONFIG["uri_out_verify_peer"] = true
    Api::Application::CONFIG["uri_out_private_key_file"] = "/etc/ssl/certs/private/api.out.local.pem"
    expect(tls_options_for("https://api-out.local/", :out)).to include ({private_key_file: "/etc/ssl/certs/private/api.out.local.pem"} )
    expect(tls_options_for("https://api-out.local/", :out)).to include ({verify_peer: true} )
  end
end
