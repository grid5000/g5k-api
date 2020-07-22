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
      get :status, params: {:site_id => "rennes", :id => "parasilo", :format => "json"}
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort).to eq ['parasilo']
      expect(json['disks']).not_to be_nil
      expect(json['nodes']['parasilo-5.rennes.grid5000.fr']['reservations']).not_to be_empty
      expect(json['disks']['sdb.parasilo-5.rennes.grid5000.fr']['reservations']).not_to be_empty
    end

    # GET /sites/{{site_id}}/clusters/{{id}}/status?network_address={{network_address}}
    it "should return the status ONLY for the specified node" do
      get :status, params: { :site_id => "rennes", :id => "parasilo", :network_address => "parasilo-5.rennes.grid5000.fr", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].keys.map{|k| k.split('.')[0]}.uniq.sort).to eq ['parasilo-5']
      expect(json['disks'].keys.map{|k| k.split('.')[1]}.uniq.sort).to eq ['parasilo-5']
      expect(json['nodes']['parasilo-5.rennes.grid5000.fr']['reservations']).not_to be_empty
      expect(json['disks']['sdb.parasilo-5.rennes.grid5000.fr']['reservations']).not_to be_empty
    end

    # GET /sites/{{site_id}}/clusters/{{id}}/status?disks=no
    it "should return the status of nodes but not disks" do
      get :status, params: { :site_id => "rennes", :id => "parasilo", :disks => "no", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort).to eq ['parasilo']
      expect(json['disks']).to be_nil
      expect(json['nodes']['parasilo-5.rennes.grid5000.fr']['reservations']).not_to be_empty
    end

    # GET /sites/{{site_id}}/clusters/{{id}}/status?job_details=no
    it "should return the status of nodes without the reservations" do
      get :status, params: { :site_id => "rennes", :id => "parasilo", :job_details => "no", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort).to eq ['parasilo']
      expect(json['disks']).not_to be_nil
      expect(json['nodes']['parasilo-5.rennes.grid5000.fr']['reservations']).to be_nil
      expect(json['disks']['sdb.parasilo-5.rennes.grid5000.fr']['reservations']).to be_nil
    end

    # GET /sites/{{site_id}}/clusters/{{id}}/status?waiting=no
    it "should not return the reservations in Waiting state" do
      get :status, params: { :site_id => "rennes", :id => "parasilo", :waiting => "no", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].keys.map{|k| k.split('-')[0]}.uniq.sort).to eq ['parasilo']
      expect(json['disks']).not_to be_nil
      expect(json['nodes']['parasilo-5.rennes.grid5000.fr']['reservations']).to be_empty
      expect(json['disks']['sdb.parasilo-5.rennes.grid5000.fr']['reservations']).to be_empty
    end

    it "should return all nodes in the specified cluster for which the status is requested" do
      get :status, params: { :site_id => "rennes", :id => "parapluie", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)
      expect(json['nodes'].length).to eq 46
      expect(json['nodes'].keys.uniq.sort).to eq ["parapluie-1.rennes.grid5000.fr", "parapluie-10.rennes.grid5000.fr", "parapluie-11.rennes.grid5000.fr", "parapluie-12.rennes.grid5000.fr", "parapluie-13.rennes.grid5000.fr", "parapluie-14.rennes.grid5000.fr", "parapluie-15.rennes.grid5000.fr", "parapluie-16.rennes.grid5000.fr", "parapluie-17.rennes.grid5000.fr", "parapluie-18.rennes.grid5000.fr", "parapluie-19.rennes.grid5000.fr", "parapluie-2.rennes.grid5000.fr", "parapluie-20.rennes.grid5000.fr", "parapluie-21.rennes.grid5000.fr", "parapluie-22.rennes.grid5000.fr", "parapluie-23.rennes.grid5000.fr", "parapluie-24.rennes.grid5000.fr", "parapluie-25.rennes.grid5000.fr", "parapluie-26.rennes.grid5000.fr", "parapluie-27.rennes.grid5000.fr", "parapluie-28.rennes.grid5000.fr", "parapluie-29.rennes.grid5000.fr", "parapluie-3.rennes.grid5000.fr", "parapluie-30.rennes.grid5000.fr", "parapluie-31.rennes.grid5000.fr", "parapluie-32.rennes.grid5000.fr", "parapluie-33.rennes.grid5000.fr", "parapluie-34.rennes.grid5000.fr", "parapluie-35.rennes.grid5000.fr", "parapluie-36.rennes.grid5000.fr", "parapluie-37.rennes.grid5000.fr", "parapluie-38.rennes.grid5000.fr", "parapluie-39.rennes.grid5000.fr", "parapluie-4.rennes.grid5000.fr", "parapluie-40.rennes.grid5000.fr", "parapluie-5.rennes.grid5000.fr", "parapluie-51.rennes.grid5000.fr", "parapluie-52.rennes.grid5000.fr", "parapluie-53.rennes.grid5000.fr", "parapluie-54.rennes.grid5000.fr", "parapluie-55.rennes.grid5000.fr", "parapluie-56.rennes.grid5000.fr", "parapluie-6.rennes.grid5000.fr", "parapluie-7.rennes.grid5000.fr", "parapluie-8.rennes.grid5000.fr", "parapluie-9.rennes.grid5000.fr"]
    end

    it "should return the status with the correct links" do
      get :status, params: { :site_id => "rennes", :id => "parapluie", :format => :json }
      expect(response.status).to eq 200
      assert_media_type(:json)

      # the "links" section should be an array with only 2 elements "self" and "parent"
      expect(json["links"]).to be_a(Array)
      expect(json["links"].length).to eq 2

      # first element is "self"
      expect(json["links"][0]).to eq({"rel"=>"self",
                                  "href"=>"/sites/rennes/clusters/parapluie/status",
                                  "type"=>"application/vnd.grid5000.item+json"})
      # second element is "parent"
      expect(json["links"][1]).to eq({"rel"=>"parent",
                                  "href"=>"/sites/rennes/clusters/parapluie",
                                  "type"=>"application/vnd.grid5000.item+json"})
    end
  end # "GET /sites/{{site_id}}/clusters/{{id}}/status"

  describe "GET /sites/{{site_id}}/clusters/{{id}}" do
    # The following unit tests check the responses at level of specific clusters:
    # 1. Where queues filter is NOT mentioned in request, for 3 types of clusters
    # 2. Where queues filter is specified as 'production'
    # 3. Where queues filter is specified as 'default'
    # 4. Where queues filter is 'production' and a 'default' cluster is requested

    it "should return ONLY cluster mbi in nancy without any queues filter" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/mbi?branch=master&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/mbi/mbi.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "mbi", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["queues"]).to eq ["admin", "production"]
    end

    it "should return ONLY cluster talc in nancy without any queues filter" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/talc?branch=master&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/talc/talc.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "talc", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["queues"]).to eq ["admin", "default"]
    end

    it "should return ONLY cluster graphique in nancy without any queues filter" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/graphique?branch=master&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/graphique/graphique.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "graphique", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["queues"] | []).to eq ["admin", "default"]
    end

    it "should return ONLY cluster mbi in nancy" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/mbi?branch=master&queues=production&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/mbi/mbi.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "mbi", :queues => "production", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["queues"]).to eq ["admin", "production"]
    end

    it "should return ONLY cluster talc in nancy" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/talc?branch=master&queues=default&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/talc/talc.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "talc", :queues => "default", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["queues"]).to eq ["admin", "default"]
    end

    it "should return NO cluster because talc is NOT production cluster" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters/talc?branch=master&queues=production&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/talc/talc.json"))
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "talc", :queues => "production", :format => :json }

      expect(response.status).to eq 404
      expect(response.body).to eq "Cannot find resource /sites/nancy/clusters/talc"
    end

    it "should return 404 if a resource does not exist" do
      get :show, params: { :branch => 'master', :site_id => "nancy", :id => "doesnotexist", :queues => "production", :format => :json }
      expect(response.status).to eq(404)
    end
  end # "GET /sites/{{site_id}}/clusters/{{id}}/"

  describe "GET /sites/{{site_id}}/clusters" do
    # The following unit tests check the responses at level of all clusters in a site:
    # 1. Where queues filter is NOT mentioned in request (mbi, talc, graphique)
    # 2. Where queues filter is specified as 'production' (mbi)
    # 3. Where queues filter is specified as 'default' (talc graphique)
    # 4. Where queues filter is 'all' (mbi, talc, graphique)

    it "should return ALL clusters in site nancy without any queues param" do
      get :index, params: { :branch => 'master', :site_id => "nancy", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["total"]).to eq 3

      clusterList = []
      json["items"].each do |cluster|
        clusterList = [cluster["uid"]] | clusterList
      end
      expect(clusterList - ["graphique","mbi","talc"]).to be_empty
    end

    it "should return ONLY cluster mbi in site nancy" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters?branch=master&queues=production&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/mbi/mbi.json"))
      get :index, params: { :branch => 'master', :site_id => "nancy", :queues => "production", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["total"]).to eq 1
      expect(json["items"][0]["uid"]).to eq "mbi"
      expect(json["items"][0]["queues"]).to include("production")
    end

    it "should return ONLY clusters talc & graphique in site nancy" do
      expected_url = "http://api-out.local:80/sites/nancy/clusters?branch=master&queues=default&pretty=yes"
      stub_request(:get, expected_url)
        .with(
          :headers => {'Accept' => api_media_type(:json)}
        )
        .to_return(:body => fixture("reference-repository/data/grid5000/sites/nancy/clusters/talc/talc.json"))
      get :index, params: { :branch => 'master', :site_id => "nancy", :queues => "default", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["total"]).to eq 2
      clusterList = []
      json["items"].each do |cluster|
        clusterList = [cluster["uid"]] | clusterList
        expect(cluster["queues"]).to include("default")
      end
      expect(clusterList - ["graphique","talc"]).to be_empty
    end

    it "should return ALL clusters in site nancy" do
      get :index, params: { :branch => 'master', :site_id => "nancy", :queues => "all", :format => :json }
      assert_media_type(:json)

      expect(response.status).to eq 200
      expect(json["total"]).to eq 3

      clusterList = []
      combined_queues = []
      json["items"].each do |cluster|
        clusterList = [cluster["uid"]] | clusterList
        combined_queues = cluster["queues"] | combined_queues
      end
      expect(combined_queues).to eq ["admin","default","production"]

      expect(clusterList - ["graphique","mbi","talc"]).to be_empty
    end
  end # "GET /sites/{{site_id}}/clusters?branch=master&queues=all&pretty=yes"
end
