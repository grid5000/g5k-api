# Copyright (c) 2014-2016 Anirvan BASU, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, environment 2.0 (the "License");
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

describe EnvironmentsController do
  render_views

  describe "GET /environments/{{id}}" do
    it "should fail if the environment does not exist" do
      get :show, params: { :id => "doesnotexist", :format => :json }
      expect(response.status).to eq(404)
      assert_vary_on :accept
      expect(response.body).to eq("Cannot find resource /environments/doesnotexist")
    end

    it "should return the environment with the correct md5 hash" do
      get :show, params: { :id => "sid-x64-base-1.0", :format => :json }
      expect(response.status).to eq(200)
      assert_media_type(:json)
      assert_vary_on :accept
      assert_allow :get
      expect(json["uid"]).to eq("sid-x64-base-1.0")
      expect(json["file"]["md5"]).to eq("e39be32c087f0c9777fd0b0ad7d12050")
      expect(json["type"]).to eq("environment")
    end
  end # describe "GET /environments/{{id}}"

  describe "GET /sites/{{site_id}}/environments/{{id}}" do
    it "should return the environment in a site with the correct md5 hash" do
      get :index, params: { :site_id => "rennes", :id => "sid-x64-base-1.0", :format => :json }
      expect(response.status).to eq(200)
      assert_media_type(:json)
      assert_vary_on :accept
      assert_allow :get
      # In this case, the body of the response is an array of hashes (json elements).
      # In the test case, just choose the first element of the array.
      first = json["items"][0]
      expect(first["uid"]).to eq("sid-x64-base-1.0")
      expect(first["file"]["md5"]).to eq("e39be32c087f0c9777fd0b0ad7d12050")
      expect(first["type"]).to eq("environment")
    end

    it "should return 404 if the site does not exist" do
      get :index, params: { :site_id => "does/not/exist", :id => "sid-x64-base-1.0", :format => :json }
      expect(response.status).to eq 404
    end
  end # describe "GET /sites/{{site_id}}/environments/{{id}}"
end
