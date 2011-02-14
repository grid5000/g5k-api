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