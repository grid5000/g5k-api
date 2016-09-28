# Copyright (c) 2015-2016 Anirvan BASU, INRIA Rennes - Bretagne Atlantique
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

describe ServersController do
  render_views

  # abasu : unit test for bug ref 7301 to handle /servers - 27.09.2016
  describe "GET /sites/{{site_id}}/servers/{{id}}" do
  # The following unit tests check the responses at level of specific servers.

    it "should return ONLY cluster talc in nancy without any queues filter" do      
      expected_url = "http://api-out.local:80/sites/nancy/servers/talc-data?branch=master&pretty=yes"
      stub_request(:get, expected_url).
        with(
          :headers => {'Accept' => media_type(:json)}
        ).
        to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/servers/talc-data.json"))
      get :show, :branch => 'master', :site_id => "nancy", :id => "talc", :format => :json
      assert_media_type(:json)

      response.status.should == 200
    end # it "should return ONLY cluster talc in nancy without any queues filter" 

  end # "GET /sites/{{site_id}}/servers/{{id}}/"



  # abasu : unit tests for bug ref 7301 to handle /servers - 27.09.2016
  describe "GET /sites/{{site_id}}/servers" do
  # The following unit tests check the responses at level of all servers in a site

    # abasu : unit test for bug ref 7301 to handle /servers - 08.01.2016
    it "should return ALL servers in site nancy" do      
      get :index, :branch => 'master', :site_id => "nancy", :format => :json
      assert_media_type(:json)

      response.status.should == 200
      json["total"].should == 1

      serverList = []
      json["items"].each do |server|
         serverList = [server["uid"]] | serverList
      end
      (serverList - ["graphique","mbi","talc"]).empty? == true

    end # it "should return ALL servers in site nancy" 

  end # "GET /sites/{{site_id}}/servers"

end # describe ServersController
