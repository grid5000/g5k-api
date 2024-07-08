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

  describe 'GET {{resource}}/versions' do
    it 'should get the list of versions' do
      get :index, params: { resource: '/sites', format: :json }
      expect(response.status).to eq(200)
      expect(json['total']).to eq(3058)
      expect(json['offset']).to eq(0)
      expect(json['items'].length).to eq(100)
      expect(json['links'].map { |l| l['rel'] }.sort).to eq(%w[parent self])
      expect(json['items'][0].keys.sort).to eq(%w[author date links message type uid])
      expect(json['items'][0]['links'].map { |l| l['rel'] }.sort).to eq(%w[parent self])
    end

    it 'should return 404 if the resource does not exist' do
      get :index, params: { resource: '/does/not/exist', format: :json }
      expect(response.status).to eq(404)
    end

    it 'should correctly deal with pagination filters' do
      get :index, params: { resource: '/sites', offset: 11, limit: 3, format: :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq 3058
      expect(json['offset']).to eq 11
      expect(json['items'].length).to eq 3
      expect(json['items'].map { |i| i['uid'] }).to eq ['934a0c5afbd52c74c888e00f3217493336563c48',
                                                        '550c137a9d39acc6726ce19cb1f82159029f86ca',
                                                        '734cccea54a4267c6d947730821ec852dffd51db']
    end

    it 'should correctly limit the number of returned items' do
      get :index, params: { resource: '/sites', offset: 11, limit: 502, format: :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq 3058
      expect(json['offset']).to eq 11
      expect(json['items'].length).to eq 500
    end
  end # describe "GET {{resource}}/versions"

  describe 'GET {{resource}}/versions/{{version_id}}' do
    it 'should fail if the version does not exist' do
      get :show, params: { resource: '/', id: 'doesnotexist', format: :json }
      expect(response.status).to eq(404)
      assert_vary_on :accept
      expect(response.body).to match "Reference (branch or commit) 'doesnotexist' cannot be found."
    end

    it 'should return the version' do
      version = '2eefdbf0e48cad1bd2db4fa9c96397df168a9c68'
      get :show, params: { resource: '/', id: version, format: :json }
      expect(response.status).to eq(200)
      assert_media_type(:json)
      assert_vary_on :accept
      assert_allow :get
      assert_expires_in 60.seconds, public: true
      expect(json['uid']).to eq(version)
      expect(json.keys.sort).to eq(%w[author date links message type uid])
      expect(json['author']).to eq('Samir Noir')
    end
  end # describe "GET {{resource}}/versions/{{version_id}}"

  describe 'GET {{resource}}/versions/latest' do
    it 'should return 307 redirect' do
      get :latest, params: { resource: 'sites/sophia/clusters/uvb', format: :json }
      expect(response.status).to eq(307)
      expect(response.location).to include("/sites/sophia/clusters/uvb/versions/206f870c99fbf69b4fb1dbdfd1703947708af611")
    end
  end # describe "GET {{resource}}/versions/latest"
end
