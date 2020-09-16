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

describe NodesController do
  render_views

  describe "GET /sites/{{site_id}}/clusters/{{cluster_id}}/nodes?deep=true" do
    it "should get the correct deep view for one site" do
      get :index, params: { site_id: 'rennes', cluster_id: 'parapide', format: :json, deep: true }
      expect(response.status).to eq 200
      expect(json['total']).to eq 17
      expect(json['items'].length).to eq 17
      expect(json['items']).to be_a(Array)
      expect(json['items'].first['uid']).to eq 'parapide-1'
    end
  end
end
