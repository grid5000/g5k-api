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

describe AccessesController do
  render_views

  describe 'GET all' do
    it 'should get all sites and ggas' do
      get :all, format: :json
      expect(response.status).to eq(200)
      expect(json).to be_a(Hash)
      # Just a simple smoke test to make sure the json is correctly populated.
      expect(json["atilf"]["abacus1"]["label"]).to eq "p3"
    end
  end

  describe 'GET /refrepo' do
    it 'should get the correct refrepo' do
      get :refrepo, format: :json
      expect(response.status).to eq 200
      expect(json['sites']).to be_a(Hash)
      expect(json['sites']).to have_key('grenoble')
    end
  end
end
