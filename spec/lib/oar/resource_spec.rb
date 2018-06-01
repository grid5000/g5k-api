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
    expect(OAR::Resource.find(:first).state).to eq "dead"
  end

  it "should return true to #dead? if resource id dead" do
    expect(OAR::Resource.where(:state => 'Dead').first).to be_dead
  end

  describe "status for multiple resource types" do
    it "should return nodes (historical behaviour) with no params" do
      expect(OAR::Resource.status.keys).to eq ["nodes"]
    end

    it "should return nodes when requesting default type" do
      expect(OAR::Resource.status({types: ['default']}).keys).to eq ["nodes"]
    end

    it "should return status for all requested resource types" do
      expect(OAR::Resource.status({types: ['node', 'disk']}).keys.sort).to eq ["nodes","disks"].sort
    end

  end

  describe "with pre-comment database schema for OAR" do
    before do
      OAR::Base.connection.execute("ALTER TABLE resources RENAME comment to comments")
      OAR::Resource.reset_column_information
    end

    it "should work on a db with no comments" do
      expect(OAR::Resource.status["nodes"].size).to be > 0
    end

    after do
      OAR::Base.connection.execute("ALTER TABLE resources RENAME comments to comment")
      OAR::Resource.reset_column_information
    end
  end

  describe "with pre-disk database schema for OAR" do
    before(:each) do
      OAR::Base.connection.execute("ALTER TABLE resources RENAME disk to renamed_disk")
      OAR::Resource.reset_column_information
    end

    it "should lists available nodes" do
      expect(OAR::Resource.status["nodes"].size).to be > 0
    end

    after(:each) do
      OAR::Base.connection.execute("ALTER TABLE resources RENAME renamed_disk to disk")
      OAR::Resource.reset_column_information
    end
  end

  describe "status for nodes" do

    it "should return the status of all the default resources" do
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
      fixture('grid5000-rennes-status-count').
        split("\n").reject{|line| line[0] == "#" || line =~ /^\s*$/}.
        map{|line| line.split(/\s/)}.
        each {|node,nb_free,nb_busy,nb_busy_best_effort|
        expected_statuses[node].merge!({:free_slots => nb_free.to_i,
                                       :freeable_slots => nb_busy.to_i,
                                       :busy_slots => nb_busy_best_effort.to_i})
      }
      OAR::Resource.status["nodes"].each do |node, status|
        expected_status = expected_statuses[node]
        expected_jobs = expected_status[:reservations].sort
        reservations = status[:reservations].map{|r| r[:uid]}.sort
        expect(reservations).to eq expected_jobs
        expect(status[:soft]).to match /#{expected_status[:soft]}/
        expect(status[:hard]).to eq expected_status[:hard]
        expect(status[:free_slots]).to eq expected_status[:free_slots]
        expect(status[:freeable_slots]).to eq expected_status[:freeable_slots]
        expect(status[:busy_slots]).to eq expected_status[:busy_slots]
      end
    end

    it "should return the status only for the resources belonging to the given clusters" do
      expect(OAR::Resource.status(:clusters => ['paradent', 'paramount'])["nodes"].keys.
               map{|n| n.split("-")[0]}.uniq.sort).to eq ['paradent', 'paramount']
    end

    it "should return the status only for the resources belonging to the given node" do
      expect(OAR::Resource.status(:network_address => 'parasilo-1.rennes.grid5000.fr')["nodes"].keys.
               map{|n| n.split(".")[0]}.uniq.sort).to eq ['parasilo-1']
    end

    it "should not return the reservations" do
      expect(OAR::Resource.status(:job_details => 'no')["nodes"].map{ |e| e[1]['reservations'] }.compact).to be_empty
    end

    it "should not return the reservations in Waiting state" do
      expect(OAR::Resource.status(:waiting => 'no', :network_address => 'parasilo-5.rennes.grid5000.fr')["nodes"].first[1]['reservations']).to be_nil
    end

    # abasu : test added to check new status values -- bug ref 5106
    it "should return a node with status free_busy" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "free_busy"
             end.map{|(node, status)| node}).to eq ["parapluie-54.rennes.grid5000.fr"]
    end  # it "should return a node with status busy_free"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return a node with status busy_free" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "busy_free"
             end.map{|(node, status)| node}).to eq ["parapluie-55.rennes.grid5000.fr"]
    end  # it "should return a node with status busy_free"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return all nodes with status busy" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "busy"
             end.map{|(node, status)| node}.sort).to eq ["paradent-9.rennes.grid5000.fr", "paradent-28.rennes.grid5000.fr", "paradent-31.rennes.grid5000.fr", "paradent-32.rennes.grid5000.fr", "paradent-33.rennes.grid5000.fr", "paradent-34.rennes.grid5000.fr", "paradent-35.rennes.grid5000.fr", "paradent-38.rennes.grid5000.fr", "paradent-39.rennes.grid5000.fr", "paradent-40.rennes.grid5000.fr", "paradent-41.rennes.grid5000.fr", "paradent-42.rennes.grid5000.fr", "paradent-43.rennes.grid5000.fr", "paradent-44.rennes.grid5000.fr", "paradent-45.rennes.grid5000.fr", "paradent-47.rennes.grid5000.fr", "paradent-48.rennes.grid5000.fr", "paradent-49.rennes.grid5000.fr", "paradent-50.rennes.grid5000.fr", "paradent-52.rennes.grid5000.fr", "paradent-53.rennes.grid5000.fr", "paradent-54.rennes.grid5000.fr", "paradent-55.rennes.grid5000.fr", "paradent-56.rennes.grid5000.fr", "paradent-57.rennes.grid5000.fr", "paradent-58.rennes.grid5000.fr", "paradent-59.rennes.grid5000.fr", "paradent-60.rennes.grid5000.fr", "paradent-61.rennes.grid5000.fr", "paradent-62.rennes.grid5000.fr", "paradent-63.rennes.grid5000.fr", "paradent-64.rennes.grid5000.fr", "parapide-10.rennes.grid5000.fr", "parapide-11.rennes.grid5000.fr", "parapide-12.rennes.grid5000.fr", "parapide-13.rennes.grid5000.fr", "parapide-14.rennes.grid5000.fr", "parapide-15.rennes.grid5000.fr", "parapide-16.rennes.grid5000.fr", "parapide-17.rennes.grid5000.fr", "parapide-18.rennes.grid5000.fr", "parapluie-9.rennes.grid5000.fr", "paramount-6.rennes.grid5000.fr", "paramount-7.rennes.grid5000.fr", "paramount-8.rennes.grid5000.fr", "paramount-9.rennes.grid5000.fr", "paramount-5.rennes.grid5000.fr", "parapide-1.rennes.grid5000.fr", "parapide-2.rennes.grid5000.fr", "parapide-3.rennes.grid5000.fr", "parapide-4.rennes.grid5000.fr", "parapide-5.rennes.grid5000.fr", "parapide-6.rennes.grid5000.fr", "parapide-7.rennes.grid5000.fr", "parapide-8.rennes.grid5000.fr", "parapide-9.rennes.grid5000.fr", "parapide-19.rennes.grid5000.fr", "parapide-20.rennes.grid5000.fr", "parapide-21.rennes.grid5000.fr", "parapide-22.rennes.grid5000.fr", "parapide-23.rennes.grid5000.fr", "parapide-24.rennes.grid5000.fr", "parapide-25.rennes.grid5000.fr", "paramount-4.rennes.grid5000.fr", "paramount-30.rennes.grid5000.fr", "paramount-32.rennes.grid5000.fr", "paramount-33.rennes.grid5000.fr", "parasilo-1.rennes.grid5000.fr", "parasilo-3.rennes.grid5000.fr"].sort
  end  # it "should return all nodes with status busy"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return all nodes with status free" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "free"
             end.map{|(node, status)| node}.sort).to eq ["paramount-29.rennes.grid5000.fr", "paramount-28.rennes.grid5000.fr", "paramount-27.rennes.grid5000.fr", "paramount-26.rennes.grid5000.fr", "paramount-24.rennes.grid5000.fr", "paramount-23.rennes.grid5000.fr", "paramount-22.rennes.grid5000.fr", "paramount-19.rennes.grid5000.fr", "paramount-18.rennes.grid5000.fr", "paramount-17.rennes.grid5000.fr", "paramount-16.rennes.grid5000.fr", "paramount-15.rennes.grid5000.fr", "paramount-14.rennes.grid5000.fr", "paramount-13.rennes.grid5000.fr", "paramount-12.rennes.grid5000.fr", "paramount-11.rennes.grid5000.fr", "paramount-10.rennes.grid5000.fr", "paramount-3.rennes.grid5000.fr", "paramount-2.rennes.grid5000.fr", "paramount-1.rennes.grid5000.fr", "paradent-2.rennes.grid5000.fr", "paradent-3.rennes.grid5000.fr", "paradent-4.rennes.grid5000.fr", "paradent-5.rennes.grid5000.fr", "paradent-6.rennes.grid5000.fr", "paradent-7.rennes.grid5000.fr", "paradent-10.rennes.grid5000.fr", "paradent-11.rennes.grid5000.fr", "paradent-12.rennes.grid5000.fr", "paradent-13.rennes.grid5000.fr", "paradent-14.rennes.grid5000.fr", "paradent-15.rennes.grid5000.fr", "paradent-16.rennes.grid5000.fr", "paradent-17.rennes.grid5000.fr", "paradent-18.rennes.grid5000.fr", "paradent-19.rennes.grid5000.fr", "paradent-20.rennes.grid5000.fr", "paradent-21.rennes.grid5000.fr", "paradent-22.rennes.grid5000.fr", "paradent-23.rennes.grid5000.fr", "paradent-24.rennes.grid5000.fr", "paradent-25.rennes.grid5000.fr", "paradent-26.rennes.grid5000.fr", "paradent-27.rennes.grid5000.fr", "paradent-29.rennes.grid5000.fr", "paradent-30.rennes.grid5000.fr", "paradent-36.rennes.grid5000.fr", "paradent-37.rennes.grid5000.fr", "paradent-51.rennes.grid5000.fr", "parapluie-7.rennes.grid5000.fr", "parapluie-20.rennes.grid5000.fr", "parapluie-21.rennes.grid5000.fr", "parapluie-8.rennes.grid5000.fr", "parapluie-22.rennes.grid5000.fr", "parapluie-23.rennes.grid5000.fr", "parapluie-24.rennes.grid5000.fr", "parapluie-25.rennes.grid5000.fr", "parapluie-26.rennes.grid5000.fr", "parapluie-27.rennes.grid5000.fr", "parapluie-28.rennes.grid5000.fr", "parapluie-29.rennes.grid5000.fr", "parapluie-3.rennes.grid5000.fr", "parapluie-30.rennes.grid5000.fr", "parapluie-31.rennes.grid5000.fr", "parapluie-32.rennes.grid5000.fr", "parapluie-33.rennes.grid5000.fr", "parapluie-34.rennes.grid5000.fr", "parapluie-35.rennes.grid5000.fr", "parapluie-36.rennes.grid5000.fr", "parapluie-37.rennes.grid5000.fr", "parapluie-38.rennes.grid5000.fr", "parapluie-39.rennes.grid5000.fr", "parapluie-4.rennes.grid5000.fr", "parapluie-40.rennes.grid5000.fr", "parapluie-5.rennes.grid5000.fr", "parapluie-6.rennes.grid5000.fr", "parapluie-2.rennes.grid5000.fr", "parapluie-19.rennes.grid5000.fr", "parapluie-18.rennes.grid5000.fr", "parapluie-17.rennes.grid5000.fr", "parapluie-16.rennes.grid5000.fr", "parapluie-15.rennes.grid5000.fr", "parapluie-14.rennes.grid5000.fr", "parapluie-13.rennes.grid5000.fr", "parapluie-12.rennes.grid5000.fr", "parapluie-11.rennes.grid5000.fr", "parapluie-10.rennes.grid5000.fr", "parapluie-1.rennes.grid5000.fr", "parasilo-2.rennes.grid5000.fr", "parasilo-5.rennes.grid5000.fr"].sort
    end  # it "should return all nodes with status free"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return a node with status free_busy_besteffort" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "free_busy_besteffort"
             end.map{|(node, status)| node}).to eq ["parapluie-51.rennes.grid5000.fr"]
    end  # it "should return a node with status free_busy_besteffort"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return a node with status busy_free_besteffort" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "busy_free_besteffort"
             end.map{|(node, status)| node}).to eq ["parapluie-52.rennes.grid5000.fr"]
    end  # it "should return a node with status busy_free_besteffort"

    # abasu : test added to check new status values -- bug ref 5106
    it "should return a node with status busy_besteffort" do
      expect(OAR::Resource.status["nodes"].select do |node, status|
               status[:soft] == "busy_besteffort"
             end.map{|(node, status)| node}).to eq ["parapluie-53.rennes.grid5000.fr"]
    end  # it "should return a node with status busy_besteffort"

    describe "standby state" do
      before do
        # resource with absent state
        @cobayes = OAR::Resource.
                     find_all_by_network_address('paramount-2.rennes.grid5000.fr')
        @cobayes.each {|r|
          expect(r.update_attribute(
                   :available_upto, OAR::Resource::STANDBY_AVAILABLE_UPTO
                 )).to be true
        }
      end

      after do
        @cobayes.each {|r|
          expect(r.update_attribute(:available_upto, 0)).to be true
        }
      end

      it "should return a standby node" do
        expect(OAR::Resource.status["nodes"].select do |node, status|
                 status[:hard] == "standby"
               end.map{|(node, status)| node}).to eq ["paramount-2.rennes.grid5000.fr"]
      end
    end
  end

  describe "Status of disks" do
    it "should return the status of all disks" do
      expected_statuses = {
        "sdb.parasilo-1.rennes.grid5000.fr" => {
          soft: "busy",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0",
          reservations: [374198]
        },
        "sdc.parasilo-1.rennes.grid5000.fr" => {
          soft: "busy",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:2:0",
          reservations: [374198]
        },
        "sdb.parasilo-5.rennes.grid5000.fr" => {
          soft: "free",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0",
          reservations: [374199]
        },
        "sdc.parasilo-5.rennes.grid5000.fr" => {
          soft: "free",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:2:0",
          reservations: [374199]
        },
        "sdb.paradent-9.rennes.grid5000.fr" => {
          soft: "free",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:1:0",
          reservations: []
        },
        "sdc.paradent-9.rennes.grid5000.fr" => {
          soft: "free",
          diskpath: "/dev/disk/by-path/pci-0000:02:00.0-scsi-0:0:2:0",
          reservations: []
        }
      }

      OAR::Resource.status(:types=>['disk'])["disks"].each do |disk, status|
        expected_status = expected_statuses[disk]
        expected_jobs = expected_status[:reservations].sort
        reservations = status[:reservations].map{|r| r[:uid]}.sort
        expect(reservations).to eq expected_jobs
        expect(status[:soft]).to eq expected_status[:soft]
        expect(status[:diskpath]).to eq expected_status[:diskpath]
      end
    end

    it "should return the status only for the disks belonging to the given clusters" do
      expect(OAR::Resource.status(:clusters => ['parasilo'],:types=>['disk'])["disks"].keys.
               map{|n| n.split('.')[1].split("-")[0]}.uniq.sort).to eq ['parasilo']
    end

    it "should return all disks with status busy" do
      expect(OAR::Resource.status(:types=>['disk'])["disks"].select do |disk, status|
               status[:soft] == "busy"
             end.map{|disk, status| disk}.sort).to eq ["sdb.parasilo-1.rennes.grid5000.fr", "sdc.parasilo-1.rennes.grid5000.fr"].sort
    end

    it "should return all disk reservations with status free" do
      expect(OAR::Resource.status(:types=>['disk'])["disks"].select do |disk, status|
               status[:soft] == "free"
             end.map{|disk, status| disk}.sort).to eq ["sdb.parasilo-5.rennes.grid5000.fr", "sdc.parasilo-5.rennes.grid5000.fr", "sdb.paradent-9.rennes.grid5000.fr", "sdc.paradent-9.rennes.grid5000.fr"].sort
    end  # it "should return all disks with status free"
  end

end # describe OAR::Resource
