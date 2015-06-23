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

describe DeploymentsController do
  render_views

  before do
    @now = Time.now
    10.times do |i|
      Factory.create(:deployment, :uid => "uid#{i}", :created_at => (@now+i).to_i).should_not be_nil
    end

  end

  describe "GET /sites/{{site_id}}/deployments" do

    it "should return the list of deployments with the correct links, in created_at DESC order" do
      get :index, :site_id => "rennes", :format => :json
      response.status.should == 200
      json['total'].should == 10
      json['offset'].should == 0
      json['items'].length.should == 10
      json['items'].map{|i| i['uid']}.should == (0...10).map{|i| "uid#{i}"}.reverse

      json['items'].all?{|i| i.has_key?('links')}.should be_true


      json['items'][0]['links'].should == [
        {
          "rel"=> "self",
          "href"=> "/sites/rennes/deployments/uid9",
          "type"=> media_type(:g5kitemjson)
        },
        {
          "rel"=> "parent",
          "href"=> "/sites/rennes",
          "type"=> media_type(:g5kitemjson)
        }
      ]
      json['links'].should == [
        {
          "rel"=>"self",
          "href"=>"/sites/rennes/deployments",
          "type"=>media_type(:g5kcollectionjson)
        },
        {
          "rel"=>"parent",
          "href"=>"/sites/rennes",
          "type"=>media_type(:g5kitemjson)
        }
      ]
    end
    it "should correctly deal with pagination filters" do
      get :index, :site_id => "rennes", :offset => 3, :limit => 5, :format => :json
      response.status.should == 200
      json['total'].should == 10
      json['offset'].should == 3
      json['items'].length.should == 5
      json['items'].map{|i| i['uid']}.should == (0...10).map{|i| "uid#{i}"}.reverse.slice(3,5)
    end
  end # describe "GET /sites/{{site_id}}/deployments"


  describe "GET /sites/{{site_id}}/deployments/{{id}}" do
    it "should return 404 if the deployment does not exist" do
      get :show, :site_id => "rennes", :id => "doesnotexist", :format => :json
      response.status.should == 404
      response.body.should =~ %r{Couldn't find Grid5000::Deployment with ID=doesnotexist}
    end
    it "should return 200 and the deployment" do
      expected_uid = "uid1"
      get :show, :site_id => "rennes", :id => expected_uid, :format => :json
      response.status.should == 200
      json["uid"].should == expected_uid
      json["links"].should be_a(Array)
      json.keys.sort.should == ["created_at", "disable_bootloader_install", "disable_disk_partitioning", "environment", "ignore_nodes_deploying", "links", "nodes", "site_uid", "status", "uid", "updated_at", "user_uid"]
    end
  end # describe "GET /sites/{{site_id}}/deployments/{{id}}"


  describe "POST /sites/{{site_id}}/deployments" do
    before do
      @valid_attributes = {
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "environment" => "lenny-x64-base"      }
      @deployment = Grid5000::Deployment.new(@valid_attributes)
    end

    it "should return 403 if the user is not authenticated" do
      authenticate_as("")
      post :create, :site_id => "rennes", :format => :json
      response.status.should == 403
      response.body.should == "You are not authorized to access this resource"
    end

    it "should fail if the deployment is not valid" do
      authenticate_as("crohr")
      send_payload(@valid_attributes.merge("nodes" => []), :json)

      post :create, :site_id => "rennes", :format => :json

      response.status.should == 400
      response.body.should =~ /The deployment you are trying to submit is not valid/
    end

    it "should raise an error if an error occurred when launching the deployment" do
      Grid5000::Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)
      @deployment.should_receive(:launch_workflow!).and_raise(Exception.new("some error message"))

      authenticate_as("crohr")
      send_payload(@valid_attributes, :json)

      post :create, :site_id => "rennes", :format => :json

      response.status.should == 500
      response.body.should == "Cannot launch deployment: some error message"
    end

    it "should return 500 if the deploymet cannot be launched" do
      Grid5000::Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)

      @deployment.should_receive(:launch_workflow!).and_return(nil)

      authenticate_as("crohr")
      send_payload(@valid_attributes, :json)

      post :create, :site_id => "rennes", :format => :json

      response.status.should == 500
      response.body.should == "Cannot launch deployment: Uid must be set"
    end

    it "should call transform_blobs_into_files! before sending the deployment, and return 201 if OK" do
      Grid5000::Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)

      @deployment.should_receive(:transform_blobs_into_files!).
        with(
          Rails.tmp,
          "http://api-in.local/sites/rennes/files"
        )

      @deployment.should_receive(:launch_workflow!).and_return(true)
      @deployment.uid="kadeploy-api-provided-wid"

      authenticate_as("crohr")
      send_payload(@valid_attributes, :json)

      post :create, :site_id => "rennes", :format => :json

      response.status.should == 201
      response.headers['Location'].should == "http://api-in.local/sites/rennes/deployments/kadeploy-api-provided-wid"

      json["uid"].should == "kadeploy-api-provided-wid"
      json["links"].should be_a(Array)
      json.keys.sort.should == ["created_at", "disable_bootloader_install", "disable_disk_partitioning", "environment", "ignore_nodes_deploying", "links", "nodes", "site_uid", "status", "uid", "updated_at", "user_uid"]

      dep = Grid5000::Deployment.find_by_uid("kadeploy-api-provided-wid")
      dep.should_not be_nil
      dep.status?(:processing).should be_true
    end
  end # describe "POST /sites/{{site_id}}/deployments"


  describe "DELETE /sites/{{site_id}}/deployments/{{id}}" do
    before do
      @deployment = Grid5000::Deployment.first
    end

    it "should return 403 if the user is not authenticated" do
      authenticate_as("")
      delete :destroy, :site_id => "rennes", :id => @deployment.uid, :format => :json
      response.status.should == 403
      response.body.should == "You are not authorized to access this resource"
    end

    it "should return 404 if the deployment does not exist" do
      authenticate_as("crohr")
      delete :destroy, :site_id => "rennes", :id => "doesnotexist", :format => :json
      response.status.should == 404
      response.body.should == "Couldn't find Grid5000::Deployment with ID=doesnotexist"
    end

    it "should return 403 if the requester does not own the deployment" do
      authenticate_as(@deployment.user_uid+"whatever")
      delete :destroy, :site_id => "rennes", :id => @deployment.uid, :format => :json
      response.status.should == 403
      response.body.should == "You are not authorized to access this resource"
    end

    it "should do nothing and return 204 if the deployment is not in an active state" do
      Grid5000::Deployment.should_receive(:find_by_uid).
        with(@deployment.uid).
        and_return(@deployment)

      @deployment.should_receive(:can_cancel?).and_return(false)

      authenticate_as(@deployment.user_uid)

      delete :destroy, :site_id => "rennes", :id => @deployment.uid, :format => :json

      response.status.should == 202
      response.headers['Location'].should == "http://api-in.local/sites/rennes/deployments/#{@deployment.uid}"
      response.body.should be_empty
    end

    it "should call Grid5000::Deployment#cancel! if deployment active" do
      Grid5000::Deployment.should_receive(:find_by_uid).
        with(@deployment.uid).
        and_return(@deployment)

      @deployment.should_receive(:can_cancel?).and_return(true)
      @deployment.should_receive(:cancel!).and_return(true)

      authenticate_as(@deployment.user_uid)

      delete :destroy, :site_id => "rennes", :id => @deployment.uid, :format => :json

      response.status.should == 202
      response.body.should be_empty
      response.headers['Location'].should == "http://api-in.local/sites/rennes/deployments/#{@deployment.uid}"
    end

  end # describe "DELETE /sites/{{site_id}}/deployments/{{id}}"

  describe "PUT /sites/{{site_id}}/deployments/{{id}}" do
    before do
      @deployment = Grid5000::Deployment.first
    end

    it "should return 404 if the deployment does not exist" do
      authenticate_as("crohr")
      put :update, :site_id => "rennes", :id => "doesnotexist", :format => :json
      response.status.should == 404
      response.body.should == "Couldn't find Grid5000::Deployment with ID=doesnotexist"
    end

    it "should call Grid5000::Deployment#touch!" do
      Grid5000::Deployment.should_receive(:find_by_uid).
        with(@deployment.uid).
        and_return(@deployment)


      @deployment.should_receive(:active?).and_return(true)
      @deployment.should_receive(:touch!)

      put :update, :site_id => "rennes", :id => @deployment.uid, :format => :json

      response.status.should == 204
      response.body.should be_empty
      response.headers['Location'].should == "http://api-in.local/sites/rennes/deployments/#{@deployment.uid}"
    end

  end # describe "PUT /sites/{{site_id}}/deployments/{{id}}"
end
