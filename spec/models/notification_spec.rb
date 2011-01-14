require 'spec_helper'

describe Notification do
  before do
    @body = "some message"
    @recipients = ["xmpp:crohr@jabber.grid5000.fr", "mailto:cyril.rohr@inria.fr"]
  end
  
  it "should correcty populate the attributes" do
    notif = Notification.new(@body, :to => @recipients)
    notif.message.should == @body
    notif.recipients.should == @recipients
  end
  
  it "should send the HTTP request to the notifications API and return true if successful" do
    stub_request(:post, "http://fake.api/sid/notifications").
      with(
        :body => "{\n  \"to\": [\n    \"xmpp:crohr@jabber.grid5000.fr\",\n    \"mailto:cyril.rohr@inria.fr\"\n  ],\n  \"body\": \"some message\"\n}", 
        :headers => {
          'Accept'=>'*/*', 
          'Content-Type'=>'application/json', 
          'X-Api-User-Privileges'=>'server', 
          'X-Api-User-Cn'=>'g5kapi'
        }
      ).
      to_return(:status => 202)
    EM.synchrony do
      notif = Notification.new(@body, :to => @recipients)
      notif.deliver!.should be_true
      EM.stop
    end
  end
  
  it "should send the HTTP request to the notifications API and return false if failed" do
    stub_request(:post, "http://fake.api/sid/notifications").
      with(
        :body => "{\n  \"to\": [\n    \"xmpp:crohr@jabber.grid5000.fr\",\n    \"mailto:cyril.rohr@inria.fr\"\n  ],\n  \"body\": \"some message\"\n}", 
        :headers => {
          'Accept'=>'*/*', 
          'Content-Type'=>'application/json', 
          'X-Api-User-Privileges'=>'server', 
          'X-Api-User-Cn'=>'g5kapi'
        }
      ).
      to_return(:status => 500)
    EM.synchrony do
      notif = Notification.new(@body, :to => @recipients)
      notif.deliver!.should be_false
      EM.stop
    end
  end
end
