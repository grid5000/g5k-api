require 'spec_helper'

describe Grid5000::SitesController do
  render_views
  
  describe "GET /grid5000/sites" do
    it "should get the correct collection of sites" do
      EM.synchrony do
        get :index, :format => :json
        response.status.should == 200
        json['total'].should == 3
        json['items'].length.should == 3
        json['items'][0]['uid'].should == 'bordeaux'
        json['items'][0]['links'].length.should == 9
        EM.stop
      end
    end
    
    it "should correctly set the URIs when X-Api-Version is present" do
      EM.synchrony do
        @request.env['HTTP_X_API_VERSION'] = 'sid'
        get :index, :format => :json
        response.status.should == 200
        json['links'][0]['href'].should =~ /^\/sid.+/
        EM.stop
      end
    end

  end # describe "GET /grid5000/sites"
  
  describe "GET /grid5000/sites/{{site_id}}" do
    it "should fail if the site does not exist" do
      EM.synchrony do
        get :show, :id => "doesnotexist", :format => :json
        response.status.should == 404
        EM.stop
      end
    end
    
    it "should return the site" do
      EM.synchrony do
        get :show, :id => "rennes", :format => :json
        response.status.should == 200
        json['uid'].should == 'rennes'
        json['links'].length.should == 9
        EM.stop
      end
    end
  end # describe "GET /grid5000/sites/{{site_id}}"
  
end
