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

  # abasu : unit test for bug ref 7301 to handle /servers - 24.10.2016
  describe "GET /sites/{{site_id}}/servers/{{id}}" do
  # The following unit tests check the responses at level of specific servers.

    it "should return ONLY cluster talc-data in nancy" do      
      get :show, :branch => 'master', :site_id => "nancy", :id => "talc-data", :format => :json
      assert_media_type(:json)
      response.body.should == '{"alias":[],"kind":"physical","monitoring":{"metric":"power","wattmeter":"multiple"},"network_adapters":{"bmc":{"ip":"172.17.79.21"},"default":{"ip":"172.16.79.21"}},"sensors":{"network":{"available":true,"resolution":1},"power":{"available":true,"resolution":1,"via":{"pdu":[{"port":20,"uid":"grisou-pdu1"},{"port":20,"uid":"grisou-pdu2"}]}}},"serial":"92ZLL82","type":"server","uid":"talc-data","warranty":11.202,"version":"2ed3470e0881a22baa43718e62098a0b8dee1e4b","links":[{"rel":"self","type":"application/vnd.grid5000.item+json","href":"/sites/nancy/servers/talc-data"},{"rel":"parent","type":"application/vnd.grid5000.item+json","href":"/sites/nancy"},{"rel":"version","type":"application/vnd.grid5000.item+json","href":"/sites/nancy/servers/talc-data/versions/2ed3470e0881a22baa43718e62098a0b8dee1e4b"},{"rel":"versions","type":"application/vnd.grid5000.collection+json","href":"/sites/nancy/servers/talc-data/versions"}]}'
      response.status.should == 200
    end # it "should return ONLY cluster talc in nancy without any queues filter" 

  end # "GET /sites/{{site_id}}/servers/{{id}}/"



  # abasu : unit tests for bug ref 7301 to handle /servers - 24.10.2016
  describe "GET /sites/{{site_id}}/servers" do
  # The following unit tests check the responses at level of all servers in a site

    # abasu : unit test for bug ref 7301 to handle /servers - 24.10.2016
    it "should return 2 servers in site nancy and their exact names" do
      get :index, :branch => 'master', :site_id => "nancy", :format => :json
      assert_media_type(:json)
      response.status.should == 200
      json["total"].should == 2

      serverList = []
      json["items"].each do |server|
         serverList = [server["uid"]] | serverList
      end
      (serverList - ["storage5k", "talc-data"]).should be_empty

    end # it "should return ALL servers in site nancy" 

  end # "GET /sites/{{site_id}}/servers"

end # describe ServersController
