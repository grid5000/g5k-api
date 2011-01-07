require 'spec_helper'

describe VersionsController do
  render_views
  
  describe "GET {{resource}}/versions" do
    it "should get the list of versions" do
      EM.synchrony do
        get :index, :resource => "/platforms/grid5000/sites", :format => :json
        response.status.should == 200
        json["total"].should == 8
        json["offset"].should == 0
        json["items"].length.should == 8
        json["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
        json["items"][0].keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
        json["items"][0]["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
        EM.stop
      end
    end
    
    it "should return 404 if the resource does not exist" do
      EM.synchrony do
        get :index, :resource => "/does/not/exist", :format => :json
        response.status.should == 404
        EM.stop
      end
    end
  end # describe "GET {{resource}}/versions"
  
  describe "GET {{resource}}/versions/{{version_id}}" do
    it "should fail if the version does not exist" do
      EM.synchrony do
        get :show, :resource => "/platforms/grid5000", :id => "doesnotexist", :format => :json
        response.status.should == 404
        assert_vary_on :accept
        json['message'].should =~ %r{The requested version 'doesnotexist' does not exist or the resource '/grid5000' does not exist.}
        EM.stop
      end
    end
    
    it "should return the version" do
      version = "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      EM.synchrony do
        get :show, :resource => "/platforms/grid5000", :id => version, :format => :json
        response.status.should == 200
        assert_media_type(:json)
        assert_vary_on :accept
        assert_allow :get
        assert_expires_in 60.seconds, :public => true
        json["uid"].should == version
        json.keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
        EM.stop
      end
    end
  end # describe "GET /grid5000/sites/{{site_id}}"
  
end
