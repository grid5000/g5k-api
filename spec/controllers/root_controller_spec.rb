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

describe RootController do
  render_views
  
  it "should return the API index" do
    get :show, :id => "grid5000", :format => :json
    response.status.should == 200
    json.should == {
      "type"=>"grid", 
      "uid"=>"grid5000", 
      "version"=>"8a562420c9a659256eeaafcfd89dfa917b5fb4d0", 
      "release"=>Grid5000::VERSION, 
      "timestamp"=>@now.to_i, 
      "links"=>[
        {"rel"=>"environments", "href"=>"/environments", "type"=>"application/vnd.grid5000.collection+json"}, 
        {"rel"=>"sites", "href"=>"/sites", "type"=>"application/vnd.grid5000.collection+json"}, 
        {"rel"=>"self", "type"=>"application/vnd.grid5000.item+json", "href"=>"/"}, 
        {"rel"=>"parent", "type"=>"application/vnd.grid5000.item+json", "href"=>"/"}, 
        {"rel"=>"version", "type"=>"application/vnd.grid5000.item+json", "href"=>"/versions/8a562420c9a659256eeaafcfd89dfa917b5fb4d0"}, 
        {"rel"=>"versions", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/versions"}, 
        {"rel"=>"users", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/users"}, 
        {"rel"=>"notifications", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/notifications"}
      ]
    }
  end
  
  it "should correcly add the api-prefix if any" do
    @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
    get :show, :id => "grid5000", :format => :json
    response.status.should == 200
    json.should == {
      "type"=>"grid", 
      "uid"=>"grid5000", 
      "version"=>"8a562420c9a659256eeaafcfd89dfa917b5fb4d0", 
      "release"=>Grid5000::VERSION, 
      "timestamp"=>@now.to_i, 
      "links"=>[
        {"rel"=>"environments", "href"=>"/sid/environments", "type"=>"application/vnd.grid5000.collection+json"}, 
        {"rel"=>"sites", "href"=>"/sid/sites", "type"=>"application/vnd.grid5000.collection+json"}, 
        {"rel"=>"self", "type"=>"application/vnd.grid5000.item+json", "href"=>"/sid/"}, 
        {"rel"=>"parent", "type"=>"application/vnd.grid5000.item+json", "href"=>"/sid/"}, 
        {"rel"=>"version", "type"=>"application/vnd.grid5000.item+json", "href"=>"/sid/versions/8a562420c9a659256eeaafcfd89dfa917b5fb4d0"}, 
        {"rel"=>"versions", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/sid/versions"}, 
        {"rel"=>"users", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/sid/users"}, 
        {"rel"=>"notifications", "type"=>"application/vnd.grid5000.collection+json", "href"=>"/sid/notifications"}
      ]
    }
  end
end
