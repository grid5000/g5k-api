require 'spec_helper'

describe RootController do
  render_views
  
  it "should return the API index" do
    get :index, :format => :json
    response.status.should == 200
    json.should == {
      "uid"=>"grid5000", 
      "links"=>[
        {"rel"=>"self", "href"=>"/", "type"=>"application/json"}, 
        {"rel"=>"sites", "href"=>"/sites", "type"=>"application/json"}
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
        {"rel"=>"self", "href"=>"/sid/", "type"=>"application/json"}, 
        {"rel"=>"sites", "href"=>"/sid/sites", "type"=>"application/json"}
      ]
    }
  end
end
