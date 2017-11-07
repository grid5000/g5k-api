# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe Grid5000::Deployment do

  before(:each) do
    @deployment = Grid5000::Deployment.new({
      :environment => "lenny-x64-base",
      :user_uid => "crohr",
      :site_uid => "rennes",
      :nodes => ["paradent-1.rennes.grid5000.fr"]
    })
  end


  describe "validations" do
    it "should be valid" do
      @deployment.should be_valid
    end

    [[], nil, ""].each do |value|
      it "should not be valid if :nodes is set to #{value.inspect}" do
        @deployment.nodes = value
        @deployment.should_not be_valid
        @deployment.errors[:nodes].
          should == ["can't be blank", "must be a non-empty list of node FQDN"]
      end
    end

    [nil, ""].each do |value|
      it "should not be valid if :environment is set to #{value.inspect}" do
        @deployment.environment = value
        @deployment.should_not be_valid
        @deployment.errors[:environment].
          should == ["can't be blank"]
      end
      it "should not be valid if :user_uid is set to  #{value.inspect}" do
        @deployment.user_uid = value
        @deployment.should_not be_valid
        @deployment.errors[:user_uid].
          should == ["can't be blank"]
      end
      it "should not be valid if :site_uid is set to  #{value.inspect}" do
        @deployment.site_uid = value
        @deployment.should_not be_valid
        @deployment.errors[:site_uid].
          should == ["can't be blank"]
      end
    end

    it "should not be valid if :notifications is not null but is not a list" do
      @deployment.notifications = ""
      @deployment.should_not be_valid
      @deployment.errors[:notifications].
        should == ["must be a list of notification URIs"]
    end
  end # describe "validations"


  describe "export to hash" do

    it "should correctly export the attributes to an array [simple]" do
      @deployment.to_hash.should == {
        "environment" => {
          "name" => "lenny-x64-base",
        },
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "hook"=>true
      }
    end

    it "should work [many nodes]" do
      @deployment.nodes = [
        "paradent-1.rennes.grid5000.fr",
        "paramount-10.rennes.grid5000.fr"
      ]
      @deployment.to_hash.should == {
        "environment" => {
          "name" => "lenny-x64-base",
        },
        "nodes" => [
          "paradent-1.rennes.grid5000.fr",
          "paramount-10.rennes.grid5000.fr",
        ],
        "hook"=>true
      }
    end

    it "should work [environment description file]" do
      @deployment.environment = "http://server.com/some/file.dsc"
      @deployment.to_hash.should == {
        "environment"=>{}, 
        "nodes"=>["paradent-1.rennes.grid5000.fr"], 
        "hook"=>true
      }    
    end

    it "should work [environment associated to a specific user]" do
      @deployment.environment = "lenny-x64-base@crohr"
      @deployment.to_hash.should == {
        "environment" => {
          "name" => "lenny-x64-base",
          "user" => "crohr",
        },
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "hook" => true
      }
    end

    it "should work [environment version]" do
      @deployment.version = 3
      @deployment.to_hash.should == {
        "environment" => {
          "name" => "lenny-x64-base",
          "version" => "3",
        },
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "hook" => true
      }
    end

    it "should work [optional parameters]" do
      @deployment.partition_number = 4
      @deployment.block_device = "whatever"
      @deployment.vlan = 3
      @deployment.reformat_tmp = "ext2"
      @deployment.ignore_nodes_deploying = true
      @deployment.disable_bootloader_install = true
      @deployment.disable_disk_partitioning = true
      @deployment.to_hash.should == {
        "environment" => {
          "name" => "lenny-x64-base",
        },
        "nodes" => ["paradent-1.rennes.grid5000.fr"],
        "deploy_part" => "4",
        "block_device" => "whatever",
        "reformat_tmp_partition" => "ext2",
        "vlan" => "3",
        "disable_disk_partitioning" => true,
        "disable_bootloader_install" => true,
        "force" => true,        
        "hook" => true
      }
    end
  end # describe "export to array"


  describe "transform blobs into files" do
    it "should transform a plain text key into a URI pointing to a physical file that contains the key content" do
      expected_filename = "crohr-key-d971f6c5dfeeaf64c9699e2a81f6d4cb5532ed96"
      @deployment.key = "ssh-dsa XMKSFNJCNJSJNJDNJSBCJSJ"
      @deployment.transform_blobs_into_files!(
        Rails.tmp,
        "https://api.grid5000.fr/sid/grid5000/sites/rennes/files")
      @deployment.key.should == "https://api.grid5000.fr/sid/grid5000/sites/rennes/files/#{expected_filename}"
      File.read(
        File.join(Rails.tmp, expected_filename)
      ).should == "ssh-dsa XMKSFNJCNJSJNJDNJSBCJSJ"
    end

    it "should do nothing if the key is already a URI" do
       @deployment.key = "http://public.rennes.grid5000.fr/~crohr/my-key.pub"
      @deployment.transform_blobs_into_files!(
         Rails.tmp,
        "https://api.grid5000.fr/sid/grid5000/sites/rennes/files")
      @deployment.key.
        should == "http://public.rennes.grid5000.fr/~crohr/my-key.pub"
    end
  end # describe "transform blobs into files"


  describe "serialization" do
    before do
      @deployment.uid = "1234"
      @deployment.notifications = [
        "xmpp:crohr@jabber.grid5000.fr",
        "mailto:cyril.rohr@irisa.fr"
      ]
      @deployment.result = {
        "paradent-1.rennes.grid5000.fr" => {
          "state" => "OK"
        }
      }
      @deployment.save.should_not be false
      @deployment.reload
    end

    it "should correctly serialize the to-be-serialized attributes" do
      @deployment.nodes.should == [
        "paradent-1.rennes.grid5000.fr"
      ]
      @deployment.notifications.should == [
        "xmpp:crohr@jabber.grid5000.fr",
        "mailto:cyril.rohr@irisa.fr"
      ]
      @deployment.result.should == {
        "paradent-1.rennes.grid5000.fr" => {
          "state" => "OK"
        }
      }
    end

    it "correctly build the attributes hash for JSON export" do
      @deployment.as_json.should == {"created_at"=>@now.to_i, "disable_bootloader_install"=>false, "disable_disk_partitioning"=>false, "environment"=>"lenny-x64-base", "ignore_nodes_deploying"=>false, "nodes"=>["paradent-1.rennes.grid5000.fr"], "notifications"=>["xmpp:crohr@jabber.grid5000.fr", "mailto:cyril.rohr@irisa.fr"], "result"=>{"paradent-1.rennes.grid5000.fr"=>{"state"=>"OK"}}, "site_uid"=>"rennes", "status"=>"waiting", "uid"=>"1234", "updated_at"=>@now.to_i, "user_uid"=>"crohr"}
    end

    it "should correctly export to json" do
      export = JSON.parse(@deployment.to_json)
      export['nodes'].should == [
        "paradent-1.rennes.grid5000.fr"]
      export['notifications'].should == [
        "xmpp:crohr@jabber.grid5000.fr",
        "mailto:cyril.rohr@irisa.fr"]
      export['result'].should == {
        "paradent-1.rennes.grid5000.fr"=>{"state"=>"OK"}
      }
    end
  end # describe "serialization"


  describe "creation" do
    it "should not allow to create a deployment if uid is nil" do
      @deployment.uid.should be_nil
      @deployment.save.should be false
      @deployment.errors[:uid].should == ["must be set"]
    end

    it "should not allow to create a deployment if uid already exists" do
      @deployment.uid = "whatever"
      @deployment.save
      dep = Grid5000::Deployment.new(@deployment.attributes)
      dep.uid = "whatever"
      dep.save.should_not be true
      dep.errors[:uid].should == ["has already been taken"]
    end

    it "should set the :created_at and :updated_at attributes" do
      @deployment.uid = "1234"
      @deployment.save.should be true
      @deployment.reload
      @deployment.uid.should == "1234"
      @deployment.created_at.should == @now.to_i
      @deployment.updated_at.should == @now.to_i
    end
  end

  describe "state transitions" do
    before do
      @deployment.uid = "some-uid"
      @deployment.save!
    end
    it "should be able to go from waiting to processing" do
      @deployment.status?(:waiting).should be true
      @deployment.should_not_receive(:deliver_notification)
      @deployment.should_receive(:launch_workflow!).and_return(true)
      @deployment.launch.should be true
      @deployment.status?(:processing).should be true
    end
    it "should not be able to go from waiting to processing if an exception is raised when launch_workflow" do
      @deployment.should_not_receive(:deliver_notification)
      @deployment.should_receive(:launch_workflow!).
        and_raise(Exception.new("some error"))
      @deployment.status?(:waiting).should be true
      lambda{
        @deployment.launch!
      }.should raise_error(Exception, "some error")
      @deployment.status?(:processing).should be false
    end

    describe "once it is in the :processing state" do
      before do
        allow(@deployment).to receive(:launch_workflow!).and_return(true)
        @deployment.launch!
        @deployment.status?(:processing).should be true
      end
      it "should be able to go from processing to processing" do
        @deployment.should_not_receive(:deliver_notification)
        @deployment.process.should be true
        @deployment.status?(:processing).should be true
      end
      it "should be able to go from processing to terminated, and should call :deliver_notification" do
        @deployment.should_receive(:deliver_notification)
        @deployment.terminate.should be true
        @deployment.status?(:terminated).should be true
      end
      it "should be able to go from processing to canceled, and should call :deliver_notification" do
        @deployment.should_receive(:cancel_workflow!).and_return(true)
        @deployment.should_receive(:deliver_notification)
        @deployment.cancel.should be true
        @deployment.status?(:canceled).should be true
      end
      it "should not be able to go from processing to canceled if an exception is raised when cancel_workflow" do
        @deployment.should_receive(:cancel_workflow!).
          and_raise(Exception.new("some error"))
        @deployment.should_not_receive(:deliver_notification)
        lambda{
          @deployment.cancel
        }.should raise_error(Exception, "some error")
        @deployment.status?(:canceled).should be false
      end
      it "should be able to go from processing to error, and should call :deliver_notification" do
        @deployment.should_receive(:deliver_notification)
        @deployment.fail.should be true
        @deployment.status?(:error).should be true
      end
      it "should not be able to go from canceled to terminated" do
        @deployment.update_attribute(:status, "canceled")
        @deployment.terminate.should be false
        @deployment.status?(:canceled).should be true
      end
    end
  end

# No more Kadeploy lib
=begin
  describe "calls to kadeploy server" do
    before do
      @kserver = Kadeploy::Server.new
      Kadeploy::Server.stub!(:new).and_return(@kserver)
    end

    describe "launch_workflow!" do
      it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
        @kserver.should_receive(:submit!).
          and_raise(Exception.new("some error"))
        lambda {
          @deployment.launch_workflow!
        }.should raise_error(Exception, "some error")
        @deployment.uid.should be_nil
      end
      it "should return the deployment uid if submission successful" do
        @kserver.should_receive(:submit!).
          and_return("some-uid")
        @deployment.launch_workflow!.should == "some-uid"
      end
    end

    describe "with a deployment in the :processing state" do

      before do
        @deployment.stub!(:launch_workflow!).and_return("some-uid")
        @deployment.launch!
        @deployment.status?(:processing).should be true
      end

      describe "cancel_workflow!" do
        it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
          @kserver.should_receive(:cancel!).
            and_raise(Exception.new("some error"))
          lambda {
            @deployment.cancel_workflow!
          }.should raise_error(Exception, "some error")
        end
        it "should return true if correctly canceled on the kadeploy-server" do
          @kserver.should_receive(:cancel!).and_return(true)
          @deployment.cancel_workflow!.should be true
        end
        it "should transition to the error state if not correctly canceled on the kadeploy-server" do
          @kserver.should_receive(:cancel!).and_return(false)
          @deployment.cancel_workflow!.should be true
          @deployment.reload.status?(:error).should be true
        end
      end

      describe "touch!" do
        before do
          @result = {"x" => "y"}
          @output = "some string"
        end

        it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
          @kserver.should_receive(:touch!).
            and_raise(Exception.new("some error"))
          lambda {
            @deployment.touch!
          }.should raise_error(Exception, "some error")
        end

        it "should set the status to :terminated if deployment is finished" do
          @kserver.should_receive(:touch!).
            and_return([:terminated, @result, @output])
          @deployment.touch!.should be true
          @deployment.reload
          @deployment.status.should == "terminated"
          @deployment.result.should == @result
          @deployment.output.should == @output
        end
        it "should set the status to :error if an error occurred while trying to fetch the results from the kadeploy server" do
          @kserver.should_receive(:touch!).
            and_return([:error, nil, @output])

          @deployment.touch!.should be true
          @deployment.reload
          @deployment.status.should == "error"
          @deployment.output.should == @output
        end
        it "should set the status to :error if the deployment no longer exist on the kadeploy server" do
          @kserver.should_receive(:touch!).
            and_return([:canceled, nil, @output])

          @deployment.touch!.should be true
          @deployment.reload
          @deployment.status.should == "error"
          @deployment.output.should == @output
        end

      end # describe "touch!"
    end # describe "with a deployment in the :processing state"
  end # describe "calls to kadeploy server"
=end

  describe "notification delivery" do

    it "should not deliver a notification if notifications is blank" do
      @deployment.notifications = nil
      Grid5000::Notification.should_not_receive(:new)
      @deployment.deliver_notification.should be true
    end

    it "should deliver a notification if notifications is not empty" do
      @deployment.notifications = ["xmpp:crohr@jabber.grid5000.fr"]
      allow(@deployment).to receive(:notification_message).and_return(msg = "msg")
      Grid5000::Notification.should_receive(:new).
        with(msg, :to => ["xmpp:crohr@jabber.grid5000.fr"]).
        and_return(notif = double("notif"))
      notif.should_receive(:deliver!).and_return(true)
      @deployment.deliver_notification.should be true
    end

    it "should always return true even if the notification delivery failed" do
      @deployment.notifications = ["xmpp:crohr@jabber.grid5000.fr"]
      allow(@deployment).to receive(:notification_message).and_return(msg = "msg")
      Grid5000::Notification.should_receive(:new).
        with(msg, :to => ["xmpp:crohr@jabber.grid5000.fr"]).
        and_return(notif = double("notif"))
      notif.should_receive(:deliver!).and_raise(Exception.new("message"))
      @deployment.deliver_notification.should be true
    end

    it "build the correct notification message" do
      @deployment.notifications = ["xmpp:crohr@jabber.grid5000.fr"]
      @deployment.notification_message.should == JSON.pretty_generate(@deployment.as_json)
    end
  end

end
