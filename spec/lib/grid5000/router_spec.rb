require 'spec_helper'

describe Grid5000::Router do
  before do
    
  end
  
  it "should take into account X-Api-Version header" do
    request = mock(Rack::MockRequest, :env => {
      'HTTP_X_API_VERSION' => 'sid'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/sites/rennes/jobs"
  end
  
  it "should take into account X-Api-Path-Prefix header" do
    request = mock(Rack::MockRequest, :env => {
      'HTTP_X_API_PATH_PREFIX' => 'grid5000'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/grid5000/sites/rennes/jobs"
  end
  
  it "should take into account both X-Api-Version and X-Api-Path-Prefix headers" do
    request = mock(Rack::MockRequest, :env => {      
      'HTTP_X_API_VERSION' => 'sid',
      'HTTP_X_API_PATH_PREFIX' => 'grid5000'
    })
    Grid5000::Router.uri_to(request, "/sites/rennes/jobs").should == "/sid/grid5000/sites/rennes/jobs"
  end
end