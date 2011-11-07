require 'spec_helper'

describe NotificationsController do
  render_views
  
  it "should return an empty list of notifications" do
    get :index, :format => :json
    response.status.should == 200
    json.should == {
      "items" => [],
      "total" => 0,
      "links"=>[
        {"rel"=>"parent", "href"=>"/"},
        {"rel"=>"self", "href"=>"/notifications"}
      ]
    }
  end
end
