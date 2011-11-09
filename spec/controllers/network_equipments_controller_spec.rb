require 'spec_helper'

describe NetworkEquipmentsController do
  render_views

  describe "GET /network_equipments" do
    it "should get 404 in default branch" do
      get :index, :format => :json
      response.status.should == 404
    end
    
    it "should get collection in testing branch" do
      get :index, :format => :json, :branch => "testing"
      response.status.should == 200
      json['total'].should == 4
      json['items'].length.should == 4
    end

    it "should get collection in testing branch" do
      get :index, :site_id => "lille", :format => :json, :branch => "testing"
      response.status.should == 200
      json['total'].should == 6
      json['items'].length.should == 6
    end
  end # describe "GET /network_equipments"

end
