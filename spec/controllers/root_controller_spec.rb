require 'spec_helper'

describe RootController do
  render_views
  
  it "should return the API index" do
    get :index, :format => :json
    response.status.should == 200
    json.should == {
      "uid"=>"grid5000", 
      "links"=>[
        {"rel"=>"self", "href"=>"/"}, 
        {"rel"=>"environments", "href"=>"/environments"},
        {"rel"=>"sites", "href"=>"/sites"},
        {"rel"=>"users", "href"=>"/users"},
        {"rel"=>"notifications", "href"=>"/notifications"}
      ]
    }
  end
  
  it "should correcly add the api-prefix if any" do
    @request.env['HTTP_X_API_PATH_PREFIX'] = 'sid'
    get :index, :format => :json
    response.status.should == 200
    json.should == {
      "uid"=>"grid5000", 
      "links"=>[
        {"rel"=>"self", "href"=>"/sid/"}, 
        {"rel"=>"environments", "href"=>"/sid/environments"},
        {"rel"=>"sites", "href"=>"/sid/sites"},
        {"rel"=>"users", "href"=>"/sid/users"},
        {"rel"=>"notifications", "href"=>"/sid/notifications"}
      ]
    }
  end
end
