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

describe OAR::Resource do

  it "should return the downcased state" do
    OAR::Resource.find(:first).state.should == "dead"
  end
  
  it "should return true to #dead? if resource id dead" do
    OAR::Resource.where(:state => 'Dead').first.should be_dead
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
          expected_statuses[node][:soft] = (job_queue == "besteffort" ? /besteffort/ : /busy/)
        end
        expected_statuses[node][:reservations].push(job_id.to_i)
      }

    OAR::Resource.status.each do |node, status|
      expected_status = expected_statuses[node]
      expected_jobs = expected_status[:reservations].sort
      reservations = status[:reservations].map{|r| r[:uid]}.sort
      reservations.should == expected_jobs
      status[:soft].should =~ /#{expected_status[:soft]}/
      status[:hard].should == expected_status[:hard]
    end
    
  end
  
  it "should return the status only for the resources belonging to the given clusters" do
    OAR::Resource.status(:clusters => ['paradent', 'paramount']).keys.
      map{|n| n.split("-")[0]}.uniq.sort.should == ['paradent', 'paramount']
  end
  
  # abasu : test added to check new status values -- bug ref 5106
  it "should return a node with status free_busy" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "free_busy"
    end.map{|(node, status)| node}.should == ["parapluie-54.rennes.grid5000.fr"]
  end  # it "should return a node with status busy_free"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return a node with status busy_free" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "busy_free"
    end.map{|(node, status)| node}.should == ["parapluie-55.rennes.grid5000.fr"]
  end  # it "should return a node with status busy_free"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return all nodes with status busy" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "busy"
    end.map{|(node, status)| node}.sort.should == ["paradent-9.rennes.grid5000.fr", "paradent-28.rennes.grid5000.fr", "paradent-31.rennes.grid5000.fr", "paradent-32.rennes.grid5000.fr", "paradent-33.rennes.grid5000.fr", "paradent-34.rennes.grid5000.fr", "paradent-35.rennes.grid5000.fr", "paradent-38.rennes.grid5000.fr", "paradent-39.rennes.grid5000.fr", "paradent-40.rennes.grid5000.fr", "paradent-41.rennes.grid5000.fr", "paradent-42.rennes.grid5000.fr", "paradent-43.rennes.grid5000.fr", "paradent-44.rennes.grid5000.fr", "paradent-45.rennes.grid5000.fr", "paradent-47.rennes.grid5000.fr", "paradent-48.rennes.grid5000.fr", "paradent-49.rennes.grid5000.fr", "paradent-50.rennes.grid5000.fr", "paradent-52.rennes.grid5000.fr", "paradent-53.rennes.grid5000.fr", "paradent-54.rennes.grid5000.fr", "paradent-55.rennes.grid5000.fr", "paradent-56.rennes.grid5000.fr", "paradent-57.rennes.grid5000.fr", "paradent-58.rennes.grid5000.fr", "paradent-59.rennes.grid5000.fr", "paradent-60.rennes.grid5000.fr", "paradent-61.rennes.grid5000.fr", "paradent-62.rennes.grid5000.fr", "paradent-63.rennes.grid5000.fr", "paradent-64.rennes.grid5000.fr", "parapide-10.rennes.grid5000.fr", "parapide-11.rennes.grid5000.fr", "parapide-12.rennes.grid5000.fr", "parapide-13.rennes.grid5000.fr", "parapide-14.rennes.grid5000.fr", "parapide-15.rennes.grid5000.fr", "parapide-16.rennes.grid5000.fr", "parapide-17.rennes.grid5000.fr", "parapide-18.rennes.grid5000.fr", "parapluie-9.rennes.grid5000.fr", "paramount-6.rennes.grid5000.fr", "paramount-7.rennes.grid5000.fr", "paramount-8.rennes.grid5000.fr", "paramount-9.rennes.grid5000.fr", "paramount-5.rennes.grid5000.fr", "parapide-1.rennes.grid5000.fr", "parapide-2.rennes.grid5000.fr", "parapide-3.rennes.grid5000.fr", "parapide-4.rennes.grid5000.fr", "parapide-5.rennes.grid5000.fr", "parapide-6.rennes.grid5000.fr", "parapide-7.rennes.grid5000.fr", "parapide-8.rennes.grid5000.fr", "parapide-9.rennes.grid5000.fr", "parapide-19.rennes.grid5000.fr", "parapide-20.rennes.grid5000.fr", "parapide-21.rennes.grid5000.fr", "parapide-22.rennes.grid5000.fr", "parapide-23.rennes.grid5000.fr", "parapide-24.rennes.grid5000.fr", "parapide-25.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr"].sort
  end  # it "should return all nodes with status busy"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return all nodes with status free" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "free"
    end.map{|(node, status)| node}.sort.should == ["paramount-29.rennes.grid5000.fr", "paramount-28.rennes.grid5000.fr", "paramount-27.rennes.grid5000.fr", "paramount-26.rennes.grid5000.fr", "paramount-24.rennes.grid5000.fr", "paramount-23.rennes.grid5000.fr", "paramount-22.rennes.grid5000.fr", "paramount-19.rennes.grid5000.fr", "paramount-18.rennes.grid5000.fr", "paramount-17.rennes.grid5000.fr", "paramount-16.rennes.grid5000.fr", "paramount-15.rennes.grid5000.fr", "paramount-14.rennes.grid5000.fr", "paramount-13.rennes.grid5000.fr", "paramount-12.rennes.grid5000.fr", "paramount-11.rennes.grid5000.fr", "paramount-10.rennes.grid5000.fr", "paramount-3.rennes.grid5000.fr", "paramount-2.rennes.grid5000.fr", "paramount-1.rennes.grid5000.fr", "paradent-2.rennes.grid5000.fr", "paradent-3.rennes.grid5000.fr", "paradent-4.rennes.grid5000.fr", "paradent-5.rennes.grid5000.fr", "paradent-6.rennes.grid5000.fr", "paradent-7.rennes.grid5000.fr", "paradent-10.rennes.grid5000.fr", "paradent-11.rennes.grid5000.fr", "paradent-12.rennes.grid5000.fr", "paradent-13.rennes.grid5000.fr", "paradent-14.rennes.grid5000.fr", "paradent-15.rennes.grid5000.fr", "paradent-16.rennes.grid5000.fr", "paradent-17.rennes.grid5000.fr", "paradent-18.rennes.grid5000.fr", "paradent-19.rennes.grid5000.fr", "paradent-20.rennes.grid5000.fr", "paradent-21.rennes.grid5000.fr", "paradent-22.rennes.grid5000.fr", "paradent-23.rennes.grid5000.fr", "paradent-24.rennes.grid5000.fr", "paradent-25.rennes.grid5000.fr", "paradent-26.rennes.grid5000.fr", "paradent-27.rennes.grid5000.fr", "paradent-29.rennes.grid5000.fr", "paradent-30.rennes.grid5000.fr", "paradent-36.rennes.grid5000.fr", "paradent-37.rennes.grid5000.fr", "paradent-51.rennes.grid5000.fr", "parapluie-7.rennes.grid5000.fr", "parapluie-20.rennes.grid5000.fr", "parapluie-21.rennes.grid5000.fr", "parapluie-8.rennes.grid5000.fr", "parapluie-22.rennes.grid5000.fr", "parapluie-23.rennes.grid5000.fr", "parapluie-24.rennes.grid5000.fr", "parapluie-25.rennes.grid5000.fr", "parapluie-26.rennes.grid5000.fr", "parapluie-27.rennes.grid5000.fr", "parapluie-28.rennes.grid5000.fr", "parapluie-29.rennes.grid5000.fr", "parapluie-3.rennes.grid5000.fr", "parapluie-30.rennes.grid5000.fr", "parapluie-31.rennes.grid5000.fr", "parapluie-32.rennes.grid5000.fr", "parapluie-33.rennes.grid5000.fr", "parapluie-34.rennes.grid5000.fr", "parapluie-35.rennes.grid5000.fr", "parapluie-36.rennes.grid5000.fr", "parapluie-37.rennes.grid5000.fr", "parapluie-38.rennes.grid5000.fr", "parapluie-39.rennes.grid5000.fr", "parapluie-4.rennes.grid5000.fr", "parapluie-40.rennes.grid5000.fr", "parapluie-5.rennes.grid5000.fr", "parapluie-6.rennes.grid5000.fr", "parapluie-2.rennes.grid5000.fr", "parapluie-19.rennes.grid5000.fr", "parapluie-18.rennes.grid5000.fr", "parapluie-17.rennes.grid5000.fr", "parapluie-16.rennes.grid5000.fr", "parapluie-15.rennes.grid5000.fr", "parapluie-14.rennes.grid5000.fr", "parapluie-13.rennes.grid5000.fr", "parapluie-12.rennes.grid5000.fr", "parapluie-11.rennes.grid5000.fr", "parapluie-10.rennes.grid5000.fr", "parapluie-1.rennes.grid5000.fr"].sort
  end  # it "should return all nodes with status free"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return a node with status free_busy_besteffort" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "free_busy_besteffort"
    end.map{|(node, status)| node}.should == ["parapluie-51.rennes.grid5000.fr"]
  end  # it "should return a node with status free_busy_besteffort"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return a node with status busy_free_besteffort" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "busy_free_besteffort"
    end.map{|(node, status)| node}.should == ["parapluie-52.rennes.grid5000.fr"]
  end  # it "should return a node with status busy_free_besteffort"

  # abasu : test added to check new status values -- bug ref 5106
  it "should return a node with status busy_besteffort" do
    OAR::Resource.status.select do |node, status|
      status[:soft] == "busy_besteffort"
    end.map{|(node, status)| node}.should == ["parapluie-53.rennes.grid5000.fr"]
  end  # it "should return a node with status busy_besteffort"


  describe "standby state" do
    before do
      # resource with absent state
      @cobayes = OAR::Resource.
        find_all_by_network_address('paramount-2.rennes.grid5000.fr')
      @cobayes.each {|r| 
        r.update_attribute(
          :available_upto, OAR::Resource::STANDBY_AVAILABLE_UPTO
        ).should be_true
      }
    end
    
    after do
      @cobayes.each {|r| 
        r.update_attribute(:available_upto, 0).should be_true
      }
    end
    
    it "should return a standby node" do
      OAR::Resource.status.select do |node, status|
        status[:hard] == "standby"
      end.map{|(node, status)| node}.should == ["paramount-2.rennes.grid5000.fr"]
    end
  end
end # describe OAR::Resource
