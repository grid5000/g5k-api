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
    @deployment = build(:deployment,
                        :environment => "lenny-x64-base",
                        :user_uid => "crohr",
                        :site_uid => "rennes",
                        :nodes => ["paradent-1.rennes.grid5000.fr"])
  end


  describe "validations" do
    it "should be valid" do
      expect(@deployment).to be_valid
    end

    [[], nil, ""].each do |value|
      it "should not be valid if :nodes is set to #{value.inspect}" do
        @deployment.nodes = value
        expect(@deployment).to_not be_valid
        expect(@deployment.errors[:nodes]).
          to eq ["can't be blank",
                 "must be a non-empty list of node FQDN"]
      end
    end

    [nil, ""].each do |value|
      it "should not be valid if :environment is set to #{value.inspect}" do
        @deployment.environment = value
        expect(@deployment).to_not be_valid
        expect(@deployment.errors[:environment]).
          to eq ["can't be blank"]
      end
      it "should not be valid if :user_uid is set to  #{value.inspect}" do
        @deployment.user_uid = value
        expect(@deployment).to_not be_valid
        expect(@deployment.errors[:user_uid]).
          to eq ["can't be blank"]
      end
      it "should not be valid if :site_uid is set to  #{value.inspect}" do
        @deployment.site_uid = value
        expect(@deployment).to_not be_valid
        expect(@deployment.errors[:site_uid]).
          to eq ["can't be blank"]
      end
    end

    it "should not be valid if :notifications is not null but is not a list" do
      @deployment.notifications = ""
      expect(@deployment).to_not be_valid
      expect(@deployment.errors[:notifications]).
        to eq ["must be a list of notification URIs"]
    end
  end # describe "validations"


  describe "export to hash" do

    it "should correctly export the attributes to an array [simple]" do
      expect(@deployment.to_hash).to be == {
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
      expect(@deployment.to_hash).to be == {
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
      expect(@deployment.to_hash).to be == {
        "environment"=>{},
        "nodes"=>["paradent-1.rennes.grid5000.fr"],
        "hook"=>true
      }
    end

    it "should work [environment associated to a specific user]" do
      @deployment.environment = "lenny-x64-base@crohr"
      expect(@deployment.to_hash).to be == {
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
      expect(@deployment.to_hash).to be == {
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
      expect(@deployment.to_hash).to be == {
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
      expect(@deployment.key).to be == "https://api.grid5000.fr/sid/grid5000/sites/rennes/files/#{expected_filename}"
      expect(File.read(
               File.join(Rails.tmp, expected_filename)
             )).to be == "ssh-dsa XMKSFNJCNJSJNJDNJSBCJSJ"
    end

    it "should do nothing if the key is already a URI" do
      @deployment.key = "http://public.rennes.grid5000.fr/~crohr/my-key.pub"
      @deployment.transform_blobs_into_files!(
         Rails.tmp,
        "https://api.grid5000.fr/sid/grid5000/sites/rennes/files")
      expect(@deployment.key).
        to be == "http://public.rennes.grid5000.fr/~crohr/my-key.pub"
    end
  end # describe "transform blobs into files"


  describe "serialization" do
    before do
      @deployment=create(:deployment,
                         uid: "1234",
                         nodes: ["paradent-1.rennes.grid5000.fr"],
                         notifications: [
                           "mailto:cyril.rohr@irisa.fr"
                         ],
                         result: {
                           "paradent-1.rennes.grid5000.fr" => {
                             "state" => "OK"
                           }
                         }
                        )
    end

    it "should correctly serialize the to-be-serialized attributes" do
      expect(@deployment.nodes).
        to be == ["paradent-1.rennes.grid5000.fr"]
      expect(@deployment.notifications).
        to be == [
             "mailto:cyril.rohr@irisa.fr"
           ]
      expect(@deployment.result).
        to be == {
        "paradent-1.rennes.grid5000.fr" => {
          "state" => "OK"
        }
      }
    end

    it "correctly build the attributes hash for JSON export" do
      expect(@deployment.as_json).to be == {"created_at"=>@now.to_i, "disable_bootloader_install"=>false, "disable_disk_partitioning"=>false, "environment"=>"lenny-x64-base", "ignore_nodes_deploying"=>false, "nodes"=>["paradent-1.rennes.grid5000.fr"], "notifications"=>["mailto:cyril.rohr@irisa.fr"], "result"=>{"paradent-1.rennes.grid5000.fr"=>{"state"=>"OK"}}, "site_uid"=>"rennes", "status"=>"waiting", "uid"=>"1234", "updated_at"=>@now.to_i, "user_uid"=>"crohr"}
    end

    it "should correctly export to json" do
      export = JSON.parse(@deployment.to_json)
      expect(export['nodes']).to be == [
        "paradent-1.rennes.grid5000.fr"]
      expect(export['notifications']).to be == [
        "mailto:cyril.rohr@irisa.fr"]
      expect(export['result']).to be == {
        "paradent-1.rennes.grid5000.fr"=>{"state"=>"OK"}
      }
    end
  end # describe "serialization"


  describe "creation" do
    it "should not allow to create a deployment if uid is nil" do
      @deployment.uid=nil
      expect(@deployment.uid).to be_nil
      expect(@deployment.save).to be false
      expect(@deployment.errors[:uid]).to be == ["must be set"]
    end

    it "should not allow to create a deployment if uid already exists" do
      @deployment.uid = "whatever"
      @deployment.save
      dep = Grid5000::Deployment.new(@deployment.attributes)
      dep.uid = "whatever"
      expect(dep.save).to_not be true
      expect(dep.errors[:uid]).to be == ["has already been taken"]
    end

    it "should set the :created_at and :updated_at attributes" do
      @deployment.uid = "1234"
      expect(@deployment.save).to be true
      @deployment.reload
      expect(@deployment.uid).to be == "1234"
      expect(@deployment.created_at).to be == @now.to_i
      expect(@deployment.updated_at).to be == @now.to_i
    end
  end

  describe "state transitions" do
    before do
      @deployment.uid = "some-uid"
      @deployment.save!
    end
    it "should be able to go from waiting to processing" do
      expect(@deployment.status?(:waiting)).to be true
      expect(@deployment).not_to receive(:deliver_notification)
      expect(@deployment).to receive(:launch_workflow!).and_return(true)
      expect(@deployment.launch).to be true
      expect(@deployment.status?(:processing)).to be true
    end
    it "should not be able to go from waiting to processing if an exception is raised when launch_workflow" do
      expect(@deployment).not_to receive(:deliver_notification)
      expect(@deployment).to receive(:launch_workflow!).
        and_raise(Exception.new("some error"))
      expect(@deployment.status?(:waiting)).to be true
      expect(lambda{
        @deployment.launch!
      }).to raise_error(Exception, "some error")
      expect(@deployment.status?(:processing)).to be false
    end

    describe "once it is in the :processing state" do
      before do
        allow(@deployment).to receive(:launch_workflow!).and_return(true)
        @deployment.launch!
        expect(@deployment.status?(:processing)).to be true
      end
      it "should be able to go from processing to processing" do
        expect(@deployment).not_to receive(:deliver_notification)
        expect(@deployment.process).to be true
        expect(@deployment.status?(:processing)).to be true
      end
      it "should be able to go from processing to terminated, and should call :deliver_notification" do
        expect(@deployment).to receive(:deliver_notification)
        expect(@deployment.terminate).to be true
        expect(@deployment.status?(:terminated)).to be true
      end
      it "should be able to go from processing to canceled, and should call :deliver_notification" do
        expect(@deployment).to receive(:cancel_workflow!).and_return(true)
        expect(@deployment).to receive(:deliver_notification)
        expect(@deployment.cancel).to be true
        expect(@deployment.status?(:canceled)).to be true
      end
      it "should not be able to go from processing to canceled if an exception is raised when cancel_workflow" do
        expect(@deployment).to receive(:cancel_workflow!).
          and_raise(Exception.new("some error"))
        expect(@deployment).not_to receive(:deliver_notification)
        expect(lambda{
          @deployment.cancel
        }).to raise_error(Exception, "some error")
        expect(@deployment.status?(:canceled)).to be false
      end
      it "should be able to go from processing to error, and should call :deliver_notification" do
        expect(@deployment).to receive(:deliver_notification)
        expect(@deployment.failed).to be true
        expect(@deployment.status?(:error)).to be true
      end
      it "should not be able to go from canceled to terminated" do
        @deployment.update_attribute(:status, "canceled")
        expect(@deployment.terminate).to be false
        expect(@deployment.status?(:canceled)).to be true
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
        expect(@kserver).to receive(:submit!).
          and_raise(Exception.new("some error"))
        lambda {
          @deployment.launch_workflow!
        expect(}).to raise_error(Exception, "some error")
        expect(@deployment.uid).to be_nil
      end
      it "should return the deployment uid if submission successful" do
        expect(@kserver).to receive(:submit!).
          and_return("some-uid")
        expect(@deployment.launch_workflow!).to be == "some-uid"
      end
    end

    describe "with a deployment in the :processing state" do

      before do
        @deployment.stub!(:launch_workflow!).and_return("some-uid")
        @deployment.launch!
        expect(@deployment.status?(:processing)).to be true
      end

      describe "cancel_workflow!" do
        it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
          expect(@kserver).to receive(:cancel!).
            and_raise(Exception.new("some error"))
          lambda {
            @deployment.cancel_workflow!
          expect(}).to raise_error(Exception, "some error")
        end
        it "should return true if correctly canceled on the kadeploy-server" do
          expect(@kserver).to receive(:cancel!).and_return(true)
          expect(@deployment.cancel_workflow!).to be true
        end
        it "should transition to the error state if not correctly canceled on the kadeploy-server" do
          expect(@kserver).to receive(:cancel!).and_return(false)
          expect(@deployment.cancel_workflow!).to be true
          expect(@deployment.reload.status?(:error)).to be true
        end
      end

      describe "touch!" do
        before do
          @result = {"x" => "y"}
          @output = "some string"
        end

        it "should raise an exception if an error occurred when trying to contact the kadeploy server" do
          expect(@kserver).to receive(:touch!).
            and_raise(Exception.new("some error"))
          lambda {
            @deployment.touch!
          expect(}).to raise_error(Exception, "some error")
        end

        it "should set the status to :terminated if deployment is finished" do
          expect(@kserver).to receive(:touch!).
            and_return([:terminated, @result, @output])
          expect(@deployment.touch!).to be true
          @deployment.reload
          expect(@deployment.status).to be == "terminated"
          expect(@deployment.result).to be == @result
          expect(@deployment.output).to be == @output
        end
        it "should set the status to :error if an error occurred while trying to fetch the results from the kadeploy server" do
          expect(@kserver).to receive(:touch!).
            and_return([:error, nil, @output])

          expect(@deployment.touch!).to be true
          @deployment.reload
          expect(@deployment.status).to be == "error"
          expect(@deployment.output).to be == @output
        end
        it "should set the status to :error if the deployment no longer exist on the kadeploy server" do
          expect(@kserver).to receive(:touch!).
            and_return([:canceled, nil, @output])

          expect(@deployment.touch!).to be true
          @deployment.reload
          expect(@deployment.status).to be == "error"
          expect(@deployment.output).to be == @output
        end

      end # describe "touch!"
    end # describe "with a deployment in the :processing status"
  end # describe "calls to kadeploy server"
=end
end
