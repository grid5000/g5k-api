require 'spec_helper'

describe OAR::Resource do
  it "should return the downcased state" do
    OAR::Resource.find(:first).state.should == "dead"
  end
  
  it "should return true to #dead? if resource id dead" do
    OAR::Resource.where(:state => 'dead').first.should be_dead
  end
  
  it "should return the status of all the resources" do
    expected_statuses = {}

    OAR::Resource.all.each{|resource|
      state = resource.state.downcase
      expected_statuses[resource.network_address] ||= {
        :hard => state,
        :soft => (state == "dead" ? "unknown" : "free"),
        :reservations => []
      }
    }
    
    fixture('grid5000-rennes-status').
      split("\n").reject{|line| line[0] == "#" || line =~ /^\s*$/}.
      uniq.map{|line| line.split(/\s/)}.
      each {|(job_id,job_queue,job_state,node,node_state)|
        if job_state =~ /running/i
          expected_statuses[node][:soft] = (job_queue == "besteffort" ? "besteffort" : "busy")
        end
        expected_statuses[node][:reservations].push(job_id.to_i)
      }

    OAR::Resource.status.each do |node, status|
      expected_status = expected_statuses[node]
      expected_jobs = expected_status[:reservations].sort
      reservations = status[:reservations].map{|r| r[:uid]}.sort
      reservations.should == expected_jobs
      status[:soft].should == expected_status[:soft]
      status[:hard].should == expected_status[:hard]
    end
    
  end
  
  it "should return the status only for the resources belonging to the given clusters" do
    OAR::Resource.status(:clusters => ['paradent', 'paramount']).keys.
      map{|n| n.split("-")[0]}.uniq.sort.should == ['paradent', 'paramount']
  end
end # describe OAR::Resource
