require 'spec_helper'

describe Grid5000::Deployment do
  
  before do
    @now = Time.now
    Time.stub!(:now).and_return(@now)
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
    
    it "should not be valid if :notifications is not null 
      but is not a list" do
      @deployment.notifications = ""
      @deployment.should_not be_valid
      @deployment.errors[:notifications].
        should == ["must be a list of notification URIs"]
    end
  end # describe "validations"
  
  
  describe "export to array" do
  
    it "should correctly export the attributes to an array [simple]" do
      @deployment.to_a.should == [
        "-e", "lenny-x64-base", 
        "-m", "paradent-1.rennes.grid5000.fr"
      ]
    end
    
    it "should work [many nodes]" do
      @deployment.nodes = [
        "paradent-1.rennes.grid5000.fr",
        "paramount-10.rennes.grid5000.fr"
      ]
      @deployment.to_a.should == [
        "-e", "lenny-x64-base", 
        "-m", "paradent-1.rennes.grid5000.fr", 
        "-m", "paramount-10.rennes.grid5000.fr"
      ]
    end
    
    it "should work [environment description file]" do
      @deployment.environment = "http://server.com/some/file.dsc"
      @deployment.to_a.should == [
        "-a", "http://server.com/some/file.dsc", 
        "-m", "paradent-1.rennes.grid5000.fr"
      ]
    end
    
    it "should work [environment associated to a specific user]" do
      @deployment.environment = "lenny-x64-base@crohr"
      @deployment.to_a.should == [
        "-e", "lenny-x64-base", 
        "-u", "crohr", 
        "-m", "paradent-1.rennes.grid5000.fr"
      ]
    end
    
    it "should work [environment version]" do
      @deployment.version = 3
      @deployment.to_a.should == [
        "-e", "lenny-x64-base", 
        "-m", "paradent-1.rennes.grid5000.fr",
        "--env-version", "3"        
      ]
    end
    
    it "should work [optional parameters]" do
      @deployment.partition_number = 4
      @deployment.block_device = "whatever"
      @deployment.vlan = 3
      @deployment.reformat_tmp = "ext2"
      @deployment.ignore_nodes_deploying = true
      @deployment.disable_bootloader_install = true
      @deployment.disable_disk_partitioning = true
      @deployment.to_a.should == [
        "-e", "lenny-x64-base", 
        "-m", "paradent-1.rennes.grid5000.fr", 
        "-p", "4", 
        "-b", "whatever", 
        "-r", "ext2", 
        "--vlan", "3",
        "--disable-disk-partitioning", 
        "--disable-bootloader-install", 
        "--ignore-nodes-deploying"
      ]
    end
  end # describe "export to array"

  
  describe "transform blobs into files" do
    it "should transform a plain text key into a URI 
      pointing to a physical file that contains the key content" do
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
      @deployment.save.should_not be_false
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
      @deployment.save.should be_false
      @deployment.errors[:uid].should == ["must be set"]
    end
    
    it "should not allow to create a deployment if uid already exists" do
      @deployment.uid = "whatever"
      @deployment.save
      dep = Grid5000::Deployment.new(@deployment.attributes)
      dep.uid = "whatever"
      dep.save.should_not be_true
      dep.errors[:uid].should == ["has already been taken"]
    end
    
    it "should set the :created_at and :updated_at attributes" do
      @deployment.uid = "1234"
      @deployment.save.should be_true
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
      @deployment.should_not_receive(:deliver_notification)
      @deployment.should_receive(:ksubmit!).and_return(true)
      @deployment.status?(:waiting).should be_true
      @deployment.launch.should be_true
      @deployment.status?(:processing).should be_true
    end
    it "should not be able to go from waiting to processing if an exception is raised when ksubmitting" do
      @deployment.should_not_receive(:deliver_notification)
      @deployment.should_receive(:ksubmit!).
        and_raise(Exception.new("some error"))
      @deployment.status?(:waiting).should be_true
      lambda{
        @deployment.launch!
      }.should raise_error(Exception, "some error")
      @deployment.status?(:processing).should be_false
    end
    
    describe "once it is in the :processing state" do
      before do
        @deployment.stub!(:ksubmit!).and_return(true)
        @deployment.launch!
        @deployment.status?(:processing).should be_true
      end
      it "should be able to go from processing to processing" do
        @deployment.should_not_receive(:deliver_notification)
        @deployment.process.should be_true
        @deployment.status?(:processing).should be_true
      end
      it "should be able to go from processing to terminated, and should call :deliver_notification" do
        @deployment.should_receive(:deliver_notification)
        @deployment.terminate.should be_true
        @deployment.status?(:terminated).should be_true
      end
      it "should be able to go from processing to canceled, and should call :deliver_notification" do
        @deployment.should_receive(:kcancel!).and_return(true)
        @deployment.should_receive(:deliver_notification)
        @deployment.cancel.should be_true
        @deployment.status?(:canceled).should be_true
      end
      it "should not be able to go from processing to canceled if an exception is raised when kcanceling" do
        @deployment.should_receive(:kcancel!).
          and_raise(Exception.new("some error"))
        @deployment.should_not_receive(:deliver_notification)
        lambda{
          @deployment.cancel
        }.should raise_error(Exception, "some error")
        @deployment.status?(:canceled).should be_false
      end
      it "should be able to go from processing to error, and should call :deliver_notification" do
        @deployment.should_receive(:deliver_notification)
        @deployment.fail.should be_true
        @deployment.status?(:error).should be_true
      end
      it "should not be able to go from canceled to terminated" do
        @deployment.should_receive(:deliver_notification)
        @deployment.should_receive(:kcancel!).and_return(true)
        @deployment.cancel!
        @deployment.terminate.should be_false
        @deployment.status?(:canceled).should be_true
      end
    end
  end
  
  describe "calls to kadeploy server" do
    before do  
      @kserver = Kadeploy::Server.new
      Kadeploy::Server.stub!(:new).and_return(@kserver)
    end
    
    describe "ksubmit!" do
      it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
        @kserver.should_receive(:submit!).
          and_raise(Exception.new("some error"))
        EM.synchrony do
          lambda {
            @deployment.ksubmit!
          }.should raise_error(Exception, "some error")
          @deployment.uid.should be_nil
          EM.stop
        end
      end
      it "should return the deployment uid if submission successful" do
        @kserver.should_receive(:submit!).
          and_return("some-uid")
        EM.synchrony do
          @deployment.ksubmit!.should == "some-uid"
          EM.stop
        end
      end
    end
    
    describe "with a deployment in the :processing state" do
   
      before do
        @deployment.stub!(:ksubmit!).and_return("some-uid")
        @deployment.launch!
        @deployment.status?(:processing).should be_true
      end
      
      describe "kcancel!" do
        it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
          @kserver.should_receive(:cancel!).
            and_raise(Exception.new("some error"))
          EM.synchrony do
            lambda {
              @deployment.kcancel!
            }.should raise_error(Exception, "some error")
            EM.stop
          end
        end
        it "should return true if correctly canceled on the kadeploy-server" do
          @kserver.should_receive(:cancel!).and_return(true)
          EM.synchrony do
            @deployment.kcancel!.should be_true
            EM.stop
          end
        end
        it "should transition to the error state if not correctly canceled on the kadeploy-server" do
          @kserver.should_receive(:cancel!).and_return(false)
          EM.synchrony do
            @deployment.kcancel!.should be_true
            @deployment.reload.status?(:error).should be_true
            EM.stop
          end
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
          EM.synchrony do
            lambda {
              @deployment.touch!
            }.should raise_error(Exception, "some error")
            EM.stop
          end
        end
        
        it "should set the status to :terminated if deployment is finished" do
          @kserver.should_receive(:touch!).
            and_return([:terminated, @result, @output])
          EM.synchrony do
            @deployment.touch!.should be_true
            @deployment.reload
            @deployment.status.should == "terminated"
            @deployment.result.should == @result
            @deployment.output.should == @output
            EM.stop
          end
        end
        it "should set the status to :error if an error occurred while trying to fetch the results from the kadeploy server" do
          @kserver.should_receive(:touch!).
            and_return([:error, nil, @output])
          
          EM.synchrony do
            @deployment.touch!.should be_true
            @deployment.reload
            @deployment.status.should == "error"
            @deployment.output.should == @output
            
            EM.stop
          end
        end
        it "should set the status to :error if the deployment no longer exist on the kadeploy server" do
          @kserver.should_receive(:touch!).
            and_return([:canceled, nil, @output])
          
          EM.synchrony do
            @deployment.touch!.should be_true
            @deployment.reload
            @deployment.status.should == "error"
            @deployment.output.should == @output
            
            EM.stop
          end
        end
        
      end # describe "touch!"
    end # describe "with a deployment in the :processing state"
  end # describe "calls to kadeploy server"
  
  describe "notification delivery" do
    
    it "should not deliver a notification if notifications is blank" do
      @deployment.notifications = nil
      Grid5000::Notification.should_not_receive(:new)
      @deployment.deliver_notification.should be_true
    end
    
    it "should deliver a notification if notifications is not empty" do
      @deployment.notifications = ["xmpp:crohr@jabber.grid5000.fr"]
      Grid5000::Notification.should_receive(:new).
        with(@deployment.as_json, :to => ["xmpp:crohr@jabber.grid5000.fr"]).
        and_return(notif = mock("notif"))
      notif.should_receive(:deliver!).and_return(true)
      @deployment.deliver_notification.should be_true
    end
    
    it "should always return true even if the notification delivery failed" do
      @deployment.notifications = ["xmpp:crohr@jabber.grid5000.fr"]
      Grid5000::Notification.should_receive(:new).
        with(@deployment.as_json, :to => ["xmpp:crohr@jabber.grid5000.fr"]).
        and_return(notif = mock("notif"))
      notif.should_receive(:deliver!).and_raise(Exception.new("message"))
      @deployment.deliver_notification.should be_true
    end
  end
    
end
