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

describe ClustersController do
  render_views

  describe "GET /sites/{{site_id}}/clusters/{{id}}/status" do
    it "should return the status ONLY for the specified cluster" do      
      get :status, :site_id => "rennes", :id => "parapluie", :format => :json
      response.status.should == 200
      assert_media_type(:json)
      json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort.should == ['parapluie']
    end # "should return the status ONLY for the specified cluster"

    it "should return all nodes in the specified cluster for which the status is requested" do      
      get :status, :site_id => "rennes", :id => "parapluie", :format => :json
      response.status.should == 200
      assert_media_type(:json)
      json['nodes'].length.should == 45
      json['nodes'].keys.uniq.sort.should == ["parapluie-1.rennes.grid5000.fr", "parapluie-10.rennes.grid5000.fr", "parapluie-11.rennes.grid5000.fr", "parapluie-12.rennes.grid5000.fr", "parapluie-13.rennes.grid5000.fr", "parapluie-14.rennes.grid5000.fr", "parapluie-15.rennes.grid5000.fr", "parapluie-16.rennes.grid5000.fr", "parapluie-17.rennes.grid5000.fr", "parapluie-18.rennes.grid5000.fr", "parapluie-19.rennes.grid5000.fr", "parapluie-2.rennes.grid5000.fr", "parapluie-20.rennes.grid5000.fr", "parapluie-21.rennes.grid5000.fr", "parapluie-22.rennes.grid5000.fr", "parapluie-23.rennes.grid5000.fr", "parapluie-24.rennes.grid5000.fr", "parapluie-25.rennes.grid5000.fr", "parapluie-26.rennes.grid5000.fr", "parapluie-27.rennes.grid5000.fr", "parapluie-28.rennes.grid5000.fr", "parapluie-29.rennes.grid5000.fr", "parapluie-3.rennes.grid5000.fr", "parapluie-30.rennes.grid5000.fr", "parapluie-31.rennes.grid5000.fr", "parapluie-32.rennes.grid5000.fr", "parapluie-33.rennes.grid5000.fr", "parapluie-34.rennes.grid5000.fr", "parapluie-35.rennes.grid5000.fr", "parapluie-36.rennes.grid5000.fr", "parapluie-37.rennes.grid5000.fr", "parapluie-38.rennes.grid5000.fr", "parapluie-39.rennes.grid5000.fr", "parapluie-4.rennes.grid5000.fr", "parapluie-40.rennes.grid5000.fr", "parapluie-5.rennes.grid5000.fr", "parapluie-51.rennes.grid5000.fr", "parapluie-52.rennes.grid5000.fr", "parapluie-53.rennes.grid5000.fr", "parapluie-54.rennes.grid5000.fr", "parapluie-55.rennes.grid5000.fr", "parapluie-6.rennes.grid5000.fr", "parapluie-7.rennes.grid5000.fr", "parapluie-8.rennes.grid5000.fr", "parapluie-9.rennes.grid5000.fr"]
    end # "should return all nodes in the specified cluster for which the status is requested"

    it "should return the status with the correct links" do      
      get :status, :site_id => "rennes", :id => "parapluie", :format => :json
      response.status.should == 200
      assert_media_type(:json)

      # the "links" section should be an array with only 2 elements "self" and "parent"
      json["links"].should be_a(Array)
      json["links"].length.should == 2

      # first element is "self"
      json["links"][0].should == {"rel"=>"self",
                                  "href"=>"/sites/parapluie/status",
                                  "type"=>"application/vnd.grid5000.item+json"}
      # second element is "parent"
      json["links"][1].should == {"rel"=>"parent",
                                  "href"=>"/sites/parapluie",
                                  "type"=>"application/vnd.grid5000.item+json"}
    end # "should return the status with the correct links"



  end # "GET /sites/{{site_id}}/clusters/{{id}}/status"

end
