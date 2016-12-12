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
  before do
    
  end
  
  it "should take into account X-Api-Version header" do
    request = mock(Rack::MockRequest, :env => {
      'HTTP_X_API_VERSION' => 'sid'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/sites/rennes/jobs"
  end
  
  it "should take into account X-Api-Path-Prefix header" do
    request = mock(Rack::MockRequest, :env => {
      'HTTP_X_API_PATH_PREFIX' => 'grid5000'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/grid5000/sites/rennes/jobs"
  end
  
  it "should take into account both X-Api-Version and X-Api-Path-Prefix headers" do
    request = mock(Rack::MockRequest, :env => {      
      'HTTP_X_API_VERSION' => 'sid',
      'HTTP_X_API_PATH_PREFIX' => 'grid5000'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/grid5000/sites/rennes/jobs"
  end

  it "should take into account the parameters of the config file with empty path" do
    Rails.my_config("base_uri_out".to_sym).should == "http://api-out.local"
    request = mock(Rack::MockRequest, :env => {
      'HTTP_X_API_VERSION' => 'sid'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/internal/oarapi/jobs/374172.json", :out).should ==  "http://api-out.local/sid/sites/rennes/internal/oarapi/jobs/374172.json"
  end

  it "should take into account the parameters of the config file with path (for dev environment)" do
    Api::Application::CONFIG["base_uri_out"] = "http://api-out.local/sid"
    Rails.my_config("base_uri_out".to_sym).should == "http://api-out.local/sid"
    request = mock(Rack::MockRequest, :env => {})
    Grid5000::Router.uri_to(request, "/sites/rennes/internal/oarapi/jobs/374172.json", :out).should ==  "http://api-out.local/sid/sites/rennes/internal/oarapi/jobs/374172.json"
  end	
	
end
