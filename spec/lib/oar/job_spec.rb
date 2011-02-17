require 'spec_helper'

describe OAR::Job do
  it "should fetch a job, and have the expected methods" do
    job = OAR::Job.first
    %w{user name queue uid state walltime}.each do |method|
      job.should respond_to(method.to_sym)
    end
  end
  
  it "should fetch the list of active jobs" do
    OAR::Job.active.map(&:uid).should == [374173, 374179, 374180, 374185, 374186, 374190, 374191]
  end
  
  it "should fetch the list of resources" do
    resources = OAR::Job.active.last.resources
    resources.map(&:id).should == [752, 753, 754, 755, 856, 857, 858, 859, 864, 865, 866, 867, 868, 869, 870, 871]
  end
  
  it "should fetch the predicted start time" do
    OAR::Job.find(374191).gantt.start_time.should == 1294395995
  end
  
  it "should fetch the job events" do
    OAR::Job.active.last.events.map(&:type).should == ["FRAG_JOB_REQUEST", "WALLTIME", "SEND_KILL_JOB", "SWITCH_INTO_ERROR_STATE"]
  end
  
  it "should dump the job" do
    result = JSON.parse(
      OAR::Job.active.find(:last, :include => [:gantt, :job_events, :job_types]).to_json
    )
    result.should == {
      "uid"=>374191, 
      "user_uid"=>"jgallard", 
      "user"=>"jgallard", 
      "queue"=>"default",
      "state"=>"running", 
      "project"=>"default",
      "types"=>["deploy"], 
      "mode"=>"INTERACTIVE", 
      "command"=>"", 
      "submitted_at"=>1294395993, 
      # "scheduled_at"=>1294395995, 
      "started_at"=>1294395995, 
      "message"=>"FIFO scheduling OK", 
      "properties"=>"((cluster='paramount') AND deploy = 'YES') AND maintenance = 'NO'", 
      "directory"=>"/home/jgallard/stagiaires10/stagiaires-nancy/partiel_from_paracancale_sajith/grid5000", 
      "events"=>[
        {
          "uid"=>950608, 
          "created_at"=>1294403214, 
          "type"=>"FRAG_JOB_REQUEST", 
          "description"=>"User root requested to frag the job 374191"
        }, 
        {
          "uid"=>950609, 
          "created_at"=>1294403214, 
          "type"=>"WALLTIME", 
          "description"=>"[sarko] Job [374191] from 1294395995 with 7200; current time=1294403214 (Elapsed)"
        }, 
        {
          "uid"=>950610, 
          "created_at"=>1294403215, 
          "type"=>"SEND_KILL_JOB", 
          "description"=>"[Leon] Send kill signal to oarexec on frontend.rennes.grid5000.fr for the job 374191"
        },
        {
          "uid"=>950611, 
          "created_at"=>1294403225, 
          "type"=>"SWITCH_INTO_ERROR_STATE", 
          "description"=>"[bipbip 374191] Ask to change the job state"
        }
      ]
    }
  end
  
  it "should build a hash of resources indexed by their type [nodes]" do
    result = OAR::Job.active.last.resources_by_type
    result.keys.should == ['nodes']
    result['nodes'].should == ["paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr"]
  end
  
  it "should build a hash of resources indexed by their type [vlans]" do
    pending "example with VLANs"
  end
  
  it "should build a hash of resources indexed by their type [subnets]" do
    pending "example with SUBNETs"
  end
end