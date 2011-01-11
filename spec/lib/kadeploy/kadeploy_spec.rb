require 'spec_helper'

module Helpers
  def mock_exec_specific_config
    exec_specific_config = mock("exec specific config", :true_user= => nil, :user= => nil)
    ConfigInformation::Config.stub!(:load_kadeploy_exec_specific).
      and_return(exec_specific_config)
    exec_specific_config
  end
end

describe Kadeploy do
  include Helpers
  before do
    @uri = "druby://kadeploy-server:25300"
    Kadeploy.instance_variable_set "@uri", nil
    Kadeploy.instance_variable_set "@logger", nil
  end
  
  describe "configuration" do
    it "should set up the kadeploy configuration" do
      Kadeploy.config = @uri
      Kadeploy.config.should == @uri
      ConfigInformation::Config.load_client_config_file.should == {
        "default" => "idontgiveashit",
        "idontgiveashit" => ["kadeploy-server", 25300]
      }
    end
    it "should set up the kadeploy logger" do
      logger = Logger.new(STDOUT)
      Kadeploy.logger = logger
      Kadeploy.logger.should == logger
    end
  end # describe "configuration"
  
  describe "connection" do
    before do
      Kadeploy.config = @uri
    end
    it "should return the server object if no block given" do
      server = Kadeploy.connect!
      server.should be_a(Kadeploy::Server)
    end
    it "should yield the server object if block given" do
      Kadeploy.connect! do |server|
        server.should be_a(Kadeploy::Server)
      end
    end
    it "should close the connection at the end of block, if block given" do
      Kadeploy.should_receive(:disconnect!).once
      Kadeploy.connect! {|server| }
    end
    it "should not close the connection if no block given" do
      Kadeploy.should_not_receive(:disconnect!)
      Kadeploy.connect!
    end
    it "should still close the connection even if an exception is raised [block given]" do
      Kadeploy.should_receive(:disconnect!).once
      lambda{Kadeploy.connect!{ |server|
        raise Exception
      }}.should raise_error(Exception)
    end
  end # describe "connection"
  
  
  describe Kadeploy::Server do
    it "should correctly initialize the handler" do
      DRbObject.should_receive(:new).with(nil, @uri).
        and_return(handler = mock(DRbObject))
      server = Kadeploy::Server.new(@uri)
      server.handler.should == handler
    end
    
    describe "operations" do
      
      before do
        DRbObject.should_receive(:new).with(nil, @uri).
          and_return(@handler = mock(DRbObject))
        @server = Kadeploy::Server.new(@uri)
        @args = [
          "-e", "lenny-x64-base",
          "-m", "paradent-1.rennes.grid5000.fr"
        ]
      end
      
      describe "submission" do
        it "should raise a Kadeploy::InvalidDeployment error
          if the deployment is invalid (invalid options)" do
          @args = ["-e", "lenny-x64-base"]
          @handler.should_not_receive(:run)
          lambda{@server.submit!(@args)}.
            should raise_error(Kadeploy::InvalidDeployment, "ERROR: You must specify some nodes to deploy.")
        end
      
        (KadeployAsyncError::NODES_DISCARDED\
        ..KadeployAsyncError::NO_ENV_CHOSEN).each do |error_code|
          it "should raise a Kadeploy::InvalidDeployment error
            if the deployment is invalid" do
            exec_specific_config = mock_exec_specific_config
            @handler.should_receive(:run).
              with("kadeploy_async", exec_specific_config, nil, nil).
              and_return([nil, error_code])
            lambda{@server.submit!(@args)}.
              should raise_error(Kadeploy::InvalidDeployment)
          end
        end
      
        it "should raise a Kadeploy::Error if an unknown error occured" do
          exec_specific_config = mock_exec_specific_config
          @handler.should_receive(:run).
            with("kadeploy_async", exec_specific_config, nil, nil).
            and_return([nil, 8])
          lambda{@server.submit!(@args)}.
            should raise_error(Kadeploy::Error, "An error occured when submitting your deployment (8). Please report to your administrator")
        end
      end # describe "submission"
      
      describe "touch!" do
        before do
          @uid = "1234"
        end
        it "should return [:processing, nil] if deployment is not in a terminated state" do
          @handler.should_receive(:async_deploy_ended?).
            with(@uid).
            and_return(false)
          @server.touch!(@uid).should == [:processing, nil]
        end
        it "should return [:canceled, nil] if the deployment does no longer exist on the kadeploy-server" do
          @handler.should_receive(:async_deploy_ended?).
            with(@uid).
            and_return(nil)
          @server.touch!(@uid).should == [:canceled, nil]
        end
        it "should return [:error, nil] if an error occurred during the deployment" do
          @handler.should_receive(:async_deploy_ended?).
            with(@uid).
            and_return(true)
          @handler.should_receive(:async_deploy_file_error?).
            with(@uid).
            and_return(FetchFileError::INVALID_ENVIRONMENT_TARBALL)
          @server.touch!(@uid).should == [:error, nil]
          @server.errors.should == ["Your environment tarball cannot be fetched"]
        end
        it "should return [:terminated, results] if the deployment was successful" do         
          @handler.should_receive(:async_deploy_ended?).
            with(@uid).
            and_return(true)
          @handler.should_receive(:async_deploy_file_error?).
            with(@uid).
            and_return(FetchFileError::NO_ERROR)
          @server.should_receive(:results!).
            with(@uid).
            and_return(results = mock("results"))
          @server.should_receive(:free!).
            with(@uid)
          @server.touch!(@uid).should == [
            :terminated,
            results
          ]
        end
      end # describe touch!
      
      describe "results!" do
        before do
          @uid = "1234"
        end
        it "should correctly fetch and format the results" do
                    example_of_kadeploy_results = {"nodes_ok"=>{"paraquad-20.rennes.grid5000.fr"=>{"last_cmd_stdout"=>"Filesystem label=\\nOS type: Linux\\nBlock size=4096 (log=2)\\nFragment size=4096 (log=2)\\n2686976 inodes, 10743460 blocks\\n537173 blocks (5.00%) reserved for the super user\\nFirst data block=0\\nMaximum filesystem blocks=4294967296\\n328 block groups\\n32768 blocks per group, 32768 fragments per group\\n8192 inodes per group\\nSuperblock backups stored on blocks: \\n\t32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, \\n\t4096000, 7962624\\n\\nWriting inode tables:   0/328\b\b\b\b\b\b\b  1/328\b\b\b\b\b\b\b  2/328\b\b\b\b\b\b\b  3/328\b\b\b\b\b\b\b  4/328\b\b\b\b\b\b\b  5/328\b\b\b\b\b\b\b  6/328\b\b\b\b\b\b\b  7/328\b\b\b\b\b\b\b  8/328\b\b\b\b\b\b\b  9/328\b\b\b\b\b\b\b 10/328\b\b\b\b\b\b\b 11/328\b\b\b\b\b\b\b 12/328\b\b\b\b\b\b\b 13/328\b\b\b\b\b\b\b 14/328\b\b\b\b\b\b\b 15/328\b\b\b\b\b\b\b 16/328\b\b\b\b\b\b\b 17/328\b\b\b\b\b\b\b 18/328\b\b\b\b\b\b\b 19/328\b\b\b\b\b\b\b 20/328\b\b\b\b\b\b\b 21/328\b\b\b\b\b\b\b 22/328\b\b\b\b\b\b\b 23/328\b\b\b\b\b\b\b 24/328\b\b\b\b\b\b\b 25/328\b\b\b\b\b\b\b 26/328\b\b\b\b\b\b\b 27/328\b\b\b\b\b\b\b 28/328\b\b\b\b\b\b\b 29/328\b\b\b\b\b\b\b 30/328\b\b\b\b\b\b\b 31/328\b\b\b\b\b\b\b 32/328\b\b\b\b\b\b\b 33/328\b\b\b\b\b\b\b 34/328\b\b\b\b\b\b\b 35/328\b\b\b\b\b\b\b 36/328\b\b\b\b\b\b\b 37/328\b\b\b\b\b\b\b 38/328\b\b\b\b\b\b\b 39/328\b\b\b\b\b\b\b 40/328\b\b\b\b\b\b\b 41/328\b\b\b\b\b\b\b 42/328\b\b\b\b\b\b\b 43/328\b\b\b\b\b\b\b 44/328\b\b\b\b\b\b\b 45/328\b\b\b\b\b\b\b 46/328\b\b\b\b\b\b\b 47/328\b\b\b\b\b\b\b 48/328\b\b\b\b\b\b\b 49/328\b\b\b\b\b\b\b 50/328\b\b\b\b\b\b\b 51/328\b\b\b\b\b\b\b 52/328\b\b\b\b\b\b\b 53/328\b\b\b\b\b\b\b 54/328\b\b\b\b\b\b\b 55/328\b\b\b\b\b\b\b 56/328\b\b\b\b\b\b\b 57/328\b\b\b\b\b\b\b 58/328\b\b\b\b\b\b\b 59/328\b\b\b\b\b\b\b 60/328\b\b\b\b\b\b\b 61/328\b\b\b\b\b\b\b 62/328\b\b\b\b\b\b\b 63/328\b\b\b\b\b\b\b 64/328\b\b\b\b\b\b\b 65/328\b\b\b\b\b\b\b 66/328\b\b\b\b\b\b\b 67/328\b\b\b\b\b\b\b 68/328\b\b\b\b\b\b\b 69/328\b\b\b\b\b\b\b 70/328\b\b\b\b\b\b\b 71/328\b\b\b\b\b\b\b 72/328\b\b\b\b\b\b\b 73/328\b\b\b\b\b\b\b 74/328\b\b\b\b\b\b\b 75/328\b\b\b\b\b\b\b 76/328\b\b\b\b\b\b\b 77/328\b\b\b\b\b\b\b 78/328\b\b\b\b\b\b\b 79/328\b\b\b\b\b\b\b 80/328\b\b\b\b\b\b\b 81/328\b\b\b\b\b\b\b 82/328\b\b\b\b\b\b\b 83/328\b\b\b\b\b\b\b 84/328\b\b\b\b\b\b\b 85/328\b\b\b\b\b\b\b 86/328\b\b\b\b\b\b\b 87/328\b\b\b\b\b\b\b 88/328\b\b\b\b\b\b\b 89/328\b\b\b\b\b\b\b 90/328\b\b\b\b\b\b\b 91/328\b\b\b\b\b\b\b 92/328\b\b\b\b\b\b\b 93/328\b\b\b\b\b\b\b 94/328\b\b\b\b\b\b\b 95/328\b\b\b\b\b\b\b 96/328\b\b\b\b\b\b\b 97/328\b\b\b\b\b\b\b 98/328\b\b\b\b\b\b\b 99/328\b\b\b\b\b\b\b100/328\b\b\b\b\b\b\b101/328\b\b\b\b\b\b\b102/328\b\b\b\b\b\b\b103/328\b\b\b\b\b\b\b104/328\b\b\b\b\b\b\b105/328\b\b\b\b\b\b\b106/328\b\b\b\b\b\b\b107/328\b\b\b\b\b\b\b108/328\b\b\b\b\b\b\b109/328\b\b\b\b\b\b\b110/328\b\b\b\b\b\b\b111/328\b\b\b\b\b\b\b112/328\b\b\b\b\b\b\b113/328\b\b\b\b\b\b\b114/328\b\b\b\b\b\b\b115/328\b\b\b\b\b\b\b116/328\b\b\b\b\b\b\b117/328\b\b\b\b\b\b\b118/328\b\b\b\b\b\b\b119/328\b\b\b\b\b\b\b120/328\b\b\b\b\b\b\b121/328\b\b\b\b\b\b\b122/328\b\b\b\b\b\b\b123/328\b\b\b\b\b\b\b124/328\b\b\b\b\b\b\b125/328\b\b\b\b\b\b\b126/328\b\b\b\b\b\b\b127/328\b\b\b\b\b\b\b128/328\b\b\b\b\b\b\b129/328\b\b\b\b\b\b\b130/328\b\b\b\b\b\b\b131/328\b\b\b\b\b\b\b132/328\b\b\b\b\b\b\b133/328\b\b\b\b\b\b\b134/328\b\b\b\b\b\b\b135/328\b\b\b\b\b\b\b136/328\b\b\b\b\b\b\b137/328\b\b\b\b\b\b\b138/328\b\b\b\b\b\b\b139/328\b\b\b\b\b\b\b140/328\b\b\b\b\b\b\b141/328\b\b\b\b\b\b\b142/328\b\b\b\b\b\b\b143/328\b\b\b\b\b\b\b144/328\b\b\b\b\b\b\b145/328\b\b\b\b\b\b\b146/328\b\b\b\b\b\b\b147/328\b\b\b\b\b\b\b148/328\b\b\b\b\b\b\b149/328\b\b\b\b\b\b\b150/328\b\b\b\b\b\b\b151/328\b\b\b\b\b\b\b152/328\b\b\b\b\b\b\b153/328\b\b\b\b\b\b\b154/328\b\b\b\b\b\b\b155/328\b\b\b\b\b\b\b156/328\b\b\b\b\b\b\b157/328\b\b\b\b\b\b\b158/328\b\b\b\b\b\b\b159/328\b\b\b\b\b\b\b160/328\b\b\b\b\b\b\b161/328\b\b\b\b\b\b\b162/328\b\b\b\b\b\b\b163/328\b\b\b\b\b\b\b164/328\b\b\b\b\b\b\b165/328\b\b\b\b\b\b\b166/328\b\b\b\b\b\b\b167/328\b\b\b\b\b\b\b168/328\b\b\b\b\b\b\b169/328\b\b\b\b\b\b\b170/328\b\b\b\b\b\b\b171/328\b\b\b\b\b\b\b172/328\b\b\b\b\b\b\b173/328\b\b\b\b\b\b\b174/328\b\b\b\b\b\b\b175/328\b\b\b\b\b\b\b176/328\b\b\b\b\b\b\b177/328\b\b\b\b\b\b\b178/328\b\b\b\b\b\b\b179/328\b\b\b\b\b\b\b180/328\b\b\b\b\b\b\b181/328\b\b\b\b\b\b\b182/328\b\b\b\b\b\b\b183/328\b\b\b\b\b\b\b184/328\b\b\b\b\b\b\b185/328\b\b\b\b\b\b\b186/328\b\b\b\b\b\b\b187/328\b\b\b\b\b\b\b188/328\b\b\b\b\b\b\b189/328\b\b\b\b\b\b\b190/328\b\b\b\b\b\b\b191/328\b\b\b\b\b\b\b192/328\b\b\b\b\b\b\b", "cmd"=>"#<Nodes::NodeCmd:0x1038ce020>", "last_cmd_stderr"=>"Filesystem label=\\nOS type: Linux\\nBlock size=4096 (log=2)\\nFragment size=4096 (log=2)\\n2686976 inodes, 10743460 blocks\\n537173 blocks (5.00%) reserved for the super user\\nFirst data block=0\\nMaximum filesystem blocks=4294967296\\n328 block groups\\n32768 blocks per group, 32768 fragments per group\\n8192 inodes per group\\nSuperblock backups stored on blocks: \\n\t32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, \\n\t4096000, 7962624\\n\\nWriting inode tables:   0/328\b\b\b\b\b\b\b  1/328\b\b\b\b\b\b\b  2/328\b\b\b\b\b\b\b  3/328\b\b\b\b\b\b\b  4/328\b\b\b\b\b\b\b  5/328\b\b\b\b\b\b\b  6/328\b\b\b\b\b\b\b  7/328\b\b\b\b\b\b\b  8/328\b\b\b\b\b\b\b  9/328\b\b\b\b\b\b\b 10/328\b\b\b\b\b\b\b 11/328\b\b\b\b\b\b\b 12/328\b\b\b\b\b\b\b 13/328\b\b\b\b\b\b\b 14/328\b\b\b\b\b\b\b 15/328\b\b\b\b\b\b\b 16/328\b\b\b\b\b\b\b 17/328\b\b\b\b\b\b\b 18/328\b\b\b\b\b\b\b 19/328\b\b\b\b\b\b\b 20/328\b\b\b\b\b\b\b 21/328\b\b\b\b\b\b\b 22/328\b\b\b\b\b\b\b 23/328\b\b\b\b\b\b\b 24/328\b\b\b\b\b\b\b 25/328\b\b\b\b\b\b\b 26/328\b\b\b\b\b\b\b 27/328\b\b\b\b\b\b\b 28/328\b\b\b\b\b\b\b 29/328\b\b\b\b\b\b\b 30/328\b\b\b\b\b\b\b 31/328\b\b\b\b\b\b\b 32/328\b\b\b\b\b\b\b 33/328\b\b\b\b\b\b\b 34/328\b\b\b\b\b\b\b 35/328\b\b\b\b\b\b\b 36/328\b\b\b\b\b\b\b 37/328\b\b\b\b\b\b\b 38/328\b\b\b\b\b\b\b 39/328\b\b\b\b\b\b\b 40/328\b\b\b\b\b\b\b 41/328\b\b\b\b\b\b\b 42/328\b\b\b\b\b\b\b 43/328\b\b\b\b\b\b\b 44/328\b\b\b\b\b\b\b 45/328\b\b\b\b\b\b\b 46/328\b\b\b\b\b\b\b 47/328\b\b\b\b\b\b\b 48/328\b\b\b\b\b\b\b 49/328\b\b\b\b\b\b\b 50/328\b\b\b\b\b\b\b 51/328\b\b\b\b\b\b\b 52/328\b\b\b\b\b\b\b 53/328\b\b\b\b\b\b\b 54/328\b\b\b\b\b\b\b 55/328\b\b\b\b\b\b\b 56/328\b\b\b\b\b\b\b 57/328\b\b\b\b\b\b\b 58/328\b\b\b\b\b\b\b 59/328\b\b\b\b\b\b\b 60/328\b\b\b\b\b\b\b 61/328\b\b\b\b\b\b\b 62/328\b\b\b\b\b\b\b 63/328\b\b\b\b\b\b\b 64/328\b\b\b\b\b\b\b 65/328\b\b\b\b\b\b\b 66/328\b\b\b\b\b\b\b 67/328\b\b\b\b\b\b\b 68/328\b\b\b\b\b\b\b 69/328\b\b\b\b\b\b\b 70/328\b\b\b\b\b\b\b 71/328\b\b\b\b\b\b\b 72/328\b\b\b\b\b\b\b 73/328\b\b\b\b\b\b\b 74/328\b\b\b\b\b\b\b 75/328\b\b\b\b\b\b\b 76/328\b\b\b\b\b\b\b 77/328\b\b\b\b\b\b\b 78/328\b\b\b\b\b\b\b 79/328\b\b\b\b\b\b\b 80/328\b\b\b\b\b\b\b 81/328\b\b\b\b\b\b\b 82/328\b\b\b\b\b\b\b 83/328\b\b\b\b\b\b\b 84/328\b\b\b\b\b\b\b 85/328\b\b\b\b\b\b\b 86/328\b\b\b\b\b\b\b 87/328\b\b\b\b\b\b\b 88/328\b\b\b\b\b\b\b 89/328\b\b\b\b\b\b\b 90/328\b\b\b\b\b\b\b 91/328\b\b\b\b\b\b\b 92/328\b\b\b\b\b\b\b 93/328\b\b\b\b\b\b\b 94/328\b\b\b\b\b\b\b 95/328\b\b\b\b\b\b\b 96/328\b\b\b\b\b\b\b 97/328\b\b\b\b\b\b\b 98/328\b\b\b\b\b\b\b 99/328\b\b\b\b\b\b\b100/328\b\b\b\b\b\b\b101/328\b\b\b\b\b\b\b102/328\b\b\b\b\b\b\b103/328\b\b\b\b\b\b\b104/328\b\b\b\b\b\b\b105/328\b\b\b\b\b\b\b106/328\b\b\b\b\b\b\b107/328\b\b\b\b\b\b\b108/328\b\b\b\b\b\b\b109/328\b\b\b\b\b\b\b110/328\b\b\b\b\b\b\b111/328\b\b\b\b\b\b\b112/328\b\b\b\b\b\b\b113/328\b\b\b\b\b\b\b114/328\b\b\b\b\b\b\b115/328\b\b\b\b\b\b\b116/328\b\b\b\b\b\b\b117/328\b\b\b\b\b\b\b118/328\b\b\b\b\b\b\b119/328\b\b\b\b\b\b\b120/328\b\b\b\b\b\b\b121/328\b\b\b\b\b\b\b122/328\b\b\b\b\b\b\b123/328\b\b\b\b\b\b\b124/328\b\b\b\b\b\b\b125/328\b\b\b\b\b\b\b126/328\b\b\b\b\b\b\b127/328\b\b\b\b\b\b\b128/328\b\b\b\b\b\b\b129/328\b\b\b\b\b\b\b130/328\b\b\b\b\b\b\b131/328\b\b\b\b\b\b\b132/328\b\b\b\b\b\b\b133/328\b\b\b\b\b\b\b134/328\b\b\b\b\b\b\b135/328\b\b\b\b\b\b\b136/328\b\b\b\b\b\b\b137/328\b\b\b\b\b\b\b138/328\b\b\b\b\b\b\b139/328\b\b\b\b\b\b\b140/328\b\b\b\b\b\b\b141/328\b\b\b\b\b\b\b142/328\b\b\b\b\b\b\b143/328\b\b\b\b\b\b\b144/328\b\b\b\b\b\b\b145/328\b\b\b\b\b\b\b146/328\b\b\b\b\b\b\b147/328\b\b\b\b\b\b\b148/328\b\b\b\b\b\b\b149/328\b\b\b\b\b\b\b150/328\b\b\b\b\b\b\b151/328\b\b\b\b\b\b\b152/328\b\b\b\b\b\b\b153/328\b\b\b\b\b\b\b154/328\b\b\b\b\b\b\b155/328\b\b\b\b\b\b\b156/328\b\b\b\b\b\b\b157/328\b\b\b\b\b\b\b158/328\b\b\b\b\b\b\b159/328\b\b\b\b\b\b\b160/328\b\b\b\b\b\b\b161/328\b\b\b\b\b\b\b162/328\b\b\b\b\b\b\b163/328\b\b\b\b\b\b\b164/328\b\b\b\b\b\b\b165/328\b\b\b\b\b\b\b166/328\b\b\b\b\b\b\b167/328\b\b\b\b\b\b\b168/328\b\b\b\b\b\b\b169/328\b\b\b\b\b\b\b170/328\b\b\b\b\b\b\b171/328\b\b\b\b\b\b\b172/328\b\b\b\b\b\b\b173/328\b\b\b\b\b\b\b174/328\b\b\b\b\b\b\b175/328\b\b\b\b\b\b\b176/328\b\b\b\b\b\b\b177/328\b\b\b\b\b\b\b178/328\b\b\b\b\b\b\b179/328\b\b\b\b\b\b\b180/328\b\b\b\b\b\b\b181/328\b\b\b\b\b\b\b182/328\b\b\b\b\b\b\b183/328\b\b\b\b\b\b\b184/328\b\b\b\b\b\b\b185/328\b\b\b\b\b\b\b186/328\b\b\b\b\b\b\b187/328\b\b\b\b\b\b\b188/328\b\b\b\b\b\b\b189/328\b\b\b\b\b\b\b190/328\b\b\b\b\b\b\b191/328\b\b\b\b\b\b\b192/328\b\b\b\b\b\b\b", "cluster"=>"paraquad", "ip"=>"131.254.202.40", "last_cmd_exit_status"=>"0", "current_step"=>nil, "state"=>"OK"}}, "nodes_ko"=>{}}

          @handler.should_receive(:async_deploy_get_results).
            with(@uid).
            and_return(example_of_kadeploy_results)
          @server.results!(@uid).should == {
            "paraquad-20.rennes.grid5000.fr"=>{"last_cmd_stdout"=>"Filesystem label=\\nOS type: Linux\\nBlock size=4096 (log=2)\\nFragment size=4096 (log=2)\\n2686976 inode", "last_cmd_stderr"=>"Filesystem label=\\nOS type: Linux\\nBlock size=4096 (log=2)\\nFragment size=4096 (log=2)\\n2686976 inode", "cluster"=>"paraquad", "ip"=>"131.254.202.40", "last_cmd_exit_status"=>0, "current_step"=>nil, "state"=>"OK"}
          }
          
        end
      end
      
    end # describe "operations"
    
  end # describe Kadeploy::Server

end # describe Kadeploy