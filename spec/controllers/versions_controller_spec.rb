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

describe VersionsController do
  render_views
  
  describe "GET {{resource}}/versions" do
    it "should get the list of versions" do
      get :index, :resource => "/sites", :format => :json
      response.status.should == 200
      # abasu - 24.10.2016 - update "total" and "length" from 8 to 10
      json["total"].should == 10
      json["offset"].should == 0
      json["items"].length.should == 10
      json["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
      json["items"][0].keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
      json["items"][0]["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
    end
    
    it "should return 404 if the resource does not exist" do
      get :index, :resource => "/does/not/exist", :format => :json
      response.status.should == 404
    end
  end # describe "GET {{resource}}/versions"
  
  describe "GET {{resource}}/versions/{{version_id}}" do
    it "should fail if the version does not exist" do
      get :show, :resource => "/", :id => "doesnotexist", :format => :json
      response.status.should == 404
      assert_vary_on :accept
      response.body.should =~ %r{The requested version 'doesnotexist' does not exist or the resource '/' does not exist.}
    end
    
    it "should return the version" do
      version = "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      get :show, :resource => "/", :id => version, :format => :json
      response.status.should == 200
      assert_media_type(:json)
      assert_vary_on :accept
      assert_allow :get
      assert_expires_in 60.seconds, :public => true
      json["uid"].should == version
      json.keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
      json["author"].should == "Cyril Rohr"
    end
  end # describe "GET {{resource}}/versions/{{version_id}}"
  
end
