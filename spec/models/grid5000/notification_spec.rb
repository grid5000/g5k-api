require 'spec_helper'

describe Grid5000::Notification do
  before do
    @body = "some message"
    @recipients = ["xmpp:crohr@jabber.grid5000.fr", "mailto:cyril.rohr@inria.fr"]
  end

  it "should have the correct URI" do
    Grid5000::Notification.uri.should == "http://fake.api/sid/notifications"
  end

  it "should correcty populate the attributes" do
    notif = Grid5000::Notification.new(@body, :to => @recipients)
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

    notif = Grid5000::Notification.new(@body, :to => @recipients)
    notif.deliver!.should be_true
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

    notif = Grid5000::Notification.new(@body, :to => @recipients)
    notif.deliver!.should be_false
  end
end
