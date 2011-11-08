require 'spec_helper'

describe VersionsController do
  render_views
  
  describe "GET {{resource}}/versions" do
    it "should get the list of versions" do
      get :index, :resource => "/sites", :format => :json
      response.status.should == 200
      json["total"].should == 8
      json["offset"].should == 0
      json["items"].length.should == 8
      json["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
      json["items"][0].keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
      json["items"][0]["links"].map{|l| l["rel"]}.sort.should == ["parent", "self"]
    end
    
    it "should return 404 if the resource does not exist" do
      get :index, :resource => "/does/not/exist", :format => :json
      response.status.should == 404
    end
  end # describe "GET {{resource}}/versions"
  
  describe "GET {{resource}}/versions/{{version_id}}" do
    it "should fail if the version does not exist" do
      get :show, :resource => "/", :id => "doesnotexist", :format => :json
      response.status.should == 404
      assert_vary_on :accept
      response.body.should =~ %r{The requested version 'doesnotexist' does not exist or the resource '/' does not exist.}
    end
    
    it "should return the version" do
      version = "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      get :show, :resource => "/", :id => version, :format => :json
      response.status.should == 200
      assert_media_type(:json)
      assert_vary_on :accept
      assert_allow :get
      assert_expires_in 60.seconds, :public => true
      json["uid"].should == version
      json.keys.sort.should == ["author", "date", "links", "message", "type", "uid"]
      json["author"].should == "Cyril Rohr"
    end
  end # describe "GET {{resource}}/versions/{{version_id}}"
  
end
