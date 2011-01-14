require 'spec_helper'

describe DeploymentsController do
  render_views
  
  before do
    @now = Time.now
    10.times do |i|
      Factory.create(:deployment, :uid => "uid#{i}", :created_at => (@now+i).to_i).should_not be_nil
    end

  end
  
  describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/deployments" do

    it "should return the list of deployments with the correct links, in created_at DESC order" do
      EM.synchrony do

        get :index, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        response.status.should == 200
        json['total'].should == 10
        json['offset'].should == 0
        json['items'].length.should == 10
        json['items'].map{|i| i['uid']}.should == (0...10).map{|i| "uid#{i}"}.reverse
        
        json['items'].all?{|i| i.has_key?('links')}.should be_true
        

        json['items'][0]['links'].should == [
          {
            "rel"=> "self", 
            "href"=> "/platforms/grid5000/sites/rennes/deployments/uid9", 
            "type"=> media_type(:json)
          }, 
          {
            "rel"=> "parent", 
            "href"=> "/platforms/grid5000/sites/rennes", 
            "type"=> media_type(:json)
          }
        ]
        json['links'].should == [
          {
            "rel"=>"self", 
            "href"=>"/platforms/grid5000/sites/rennes/deployments", 
            "type"=>media_type(:json_collection)
          }, 
          {
            "rel"=>"parent", 
            "href"=>"/platforms/grid5000/sites/rennes", 
            "type"=>media_type(:json)
          }
        ]
        
        EM.stop
      end
    end
    it "should correctly deal with pagination filters" do
      EM.synchrony do
        get :index, :platform_id => "grid5000", :site_id => "rennes", :offset => 3, :limit => 5, :format => :json
        response.status.should == 200
        json['total'].should == 10
        json['offset'].should == 3
        json['items'].length.should == 5
        json['items'].map{|i| i['uid']}.should == (0...10).map{|i| "uid#{i}"}.reverse.slice(3,5)
        EM.stop
      end
    end
  end # describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/deployments"
  
  
  describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}" do
    it "should return 404 if the deployment does not exist" do
      EM.synchrony do
        get :show, :platform_id => "grid5000", :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find Deployment with ID=doesnotexist"
        EM.stop
      end
    end
    it "should return 200 and the deployment" do
      EM.synchrony do
        expected_uid = "uid1"
        get :show, :platform_id => "grid5000", :site_id => "rennes", :id => expected_uid, :format => :json
        response.status.should == 200
        json["uid"].should == expected_uid
        json["links"].should be_a(Array)
        json.keys.sort.should == ["created_at", "disable_bootloader_install", "disable_disk_partitioning", "environment", "ignore_nodes_deploying", "links", "nodes", "site_uid", "status", "uid", "updated_at", "user_uid"]
        EM.stop
      end
    end
  end # describe "GET /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}"
  
  
  
  describe "POST /platforms/{{platform_id}}/sites/{{site_id}}/deployments" do
    before do
      @valid_attributes = {
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "environment" => "lenny-x64-base"
      }
      @deployment = Deployment.new(@valid_attributes)
    end
    
    it "should return 403 if the user is not authenticated" do
      EM.synchrony do
        authenticate_as("")
        post :create, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    
    it "should fail if the deployment is not valid" do
      EM.synchrony do
        authenticate_as("crohr")
        send_payload(@valid_attributes.merge("nodes" => []), :json)
        
        post :create, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        
        response.status.should == 400
        json['message'].should =~ /The deployment you are trying to submit is not valid/
        EM.stop
      end
    end
    
    it "should raise an error if an error occurred when launching the deployment" do
      Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)
      @deployment.should_receive(:ksubmit!).and_raise(Exception.new("some error message"))
      
      EM.synchrony do
        authenticate_as("crohr")
        send_payload(@valid_attributes, :json)
        
        post :create, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        
        response.status.should == 500
        json['message'].should == "some error message"
        
        EM.stop
      end
    end
    
    it "should return 500 if the deploymet cannot be launched" do
      Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)
        
      @deployment.should_receive(:ksubmit!).and_return(nil)
      
      EM.synchrony do
        authenticate_as("crohr")
        send_payload(@valid_attributes, :json)
        
        post :create, :platform_id => "grid5000", :site_id => "rennes", :format => :json
        
        response.status.should == 500
        json['message'].should == "Cannot launch deployment: Uid must be set"
        
        EM.stop
      end
    end
    
    it "should call transform_blobs_into_files! before sending the deployment, and return 201 if OK" do      
      Deployment.should_receive(:new).with(@valid_attributes).
        and_return(@deployment)
        
      @deployment.should_receive(:transform_blobs_into_files!).
        with(
          Rails.tmp, 
          "http://api-in.local/platforms/grid5000/sites/rennes/files"
        )

      @deployment.should_receive(:ksubmit!).and_return("some-uid")
      
      EM.synchrony do
        
        authenticate_as("crohr")
        send_payload(@valid_attributes, :json)
        
        post :create, :platform_id => "grid5000", :site_id => "rennes", :format => :json

        response.status.should == 201
        response.headers['Location'].should == "http://api-in.local/platforms/grid5000/sites/rennes/deployments/some-uid"
        response.body.should be_empty
        
        dep = Deployment.find_by_uid("some-uid")
        dep.should_not be_nil
        dep.status?(:processing).should be_true
        
        EM.stop
      end
    end
  end # describe "POST /platforms/{{platform_id}}/sites/{{site_id}}/deployments"
  
  
  describe "DELETE /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}" do
    before do
      @deployment = Deployment.first
    end
    
    it "should return 403 if the user is not authenticated" do
      EM.synchrony do
        authenticate_as("")
        delete :destroy, :platform_id => "grid5000", :site_id => "rennes", :id => @deployment.uid, :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    
    it "should return 404 if the deployment does not exist" do
      EM.synchrony do
        authenticate_as("crohr")
        delete :destroy, :platform_id => "grid5000", :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find Deployment with ID=doesnotexist"
        EM.stop
      end
    end
    
    it "should return 403 if the requester does not own the deployment" do
      EM.synchrony do
        authenticate_as(@deployment.user_uid+"whatever")
        delete :destroy, :platform_id => "grid5000", :site_id => "rennes", :id => @deployment.uid, :format => :json
        response.status.should == 403
        json['message'].should == "You are not authorized to access this resource"
        EM.stop
      end
    end
    
    it "should do nothing and return 204 if the deployment is not in an active state" do
      EM.synchrony do
        Deployment.should_receive(:find).with(@deployment.uid).
          and_return(@deployment)
          
        @deployment.should_receive(:can_cancel?).and_return(false)
        
        authenticate_as(@deployment.user_uid)
        
        delete :destroy, :platform_id => "grid5000", :site_id => "rennes", :id => @deployment.uid, :format => :json

        response.status.should == 204
        response.headers['Location'].should == "http://api-in.local/platforms/grid5000/sites/rennes/deployments/#{@deployment.uid}"
        response.body.should be_empty
        
        EM.stop
      end
    end
    
    it "should call Deployment#cancel! if deployment active" do
      Deployment.should_receive(:find).with(@deployment.uid).
        and_return(@deployment)
        
      @deployment.should_receive(:can_cancel?).and_return(true)
      @deployment.should_receive(:cancel!).and_return(true)
      
      EM.synchrony do
        authenticate_as(@deployment.user_uid)
        
        delete :destroy, :platform_id => "grid5000", :site_id => "rennes", :id => @deployment.uid, :format => :json
        
        response.status.should == 204
        response.body.should be_empty
        response.headers['Location'].should == "http://api-in.local/platforms/grid5000/sites/rennes/deployments/#{@deployment.uid}"        
        EM.stop
      end
    end
    
  end # describe "DELETE /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}"
  
  describe "PUT /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}" do
    before do
      @deployment = Deployment.first
    end
    
    it "should return 404 if the deployment does not exist" do
      EM.synchrony do
        authenticate_as("crohr")
        put :update, :platform_id => "grid5000", :site_id => "rennes", :id => "doesnotexist", :format => :json
        response.status.should == 404
        json['message'].should == "Couldn't find Deployment with ID=doesnotexist"
        EM.stop
      end
    end
    
    it "should call Deployment#touch!" do
      Deployment.should_receive(:find).with(@deployment.uid).
        and_return(@deployment)
        
        
      @deployment.should_receive(:active?).and_return(true)
      @deployment.should_receive(:touch!)
      
      EM.synchrony do
        
        put :update, :platform_id => "grid5000", :site_id => "rennes", :id => @deployment.uid, :format => :json
        
        response.status.should == 204
        response.body.should be_empty
        response.headers['Location'].should == "http://api-in.local/platforms/grid5000/sites/rennes/deployments/#{@deployment.uid}"
        
        EM.stop
      end
    end

  end # describe "PUT /platforms/{{platform_id}}/sites/{{site_id}}/deployments/{{id}}"
end
