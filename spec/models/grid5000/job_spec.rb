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

describe Grid5000::Job do
  describe "normalization" do
    it "should transform into integers a few properties" do
      now = Time.now
      job = Grid5000::Job.new(:exit_code => "0", :submitted_at => "12345", :started_at => "6789", :reservation => now, :signal => "1", :uid => "12321", :anterior => "34543", :scheduled_at => "56765", :walltime => "3600", :checkpoint => "7200")
      job.exit_code.should == 0
      job.submitted_at.should == 12345
      job.started_at.should == 6789
      job.reservation.should == now.to_i
      job.signal.should == 1
      job.uid.should == 12321
      job.anterior.should == 34543
      job.scheduled_at.should == 56765
      job.walltime.should == 3600
      job.checkpoint.should == 7200
    end
  end
  
  describe "Exporting to a hash" do
    before do
      @job = Grid5000::Job.new(
        "walltime"=>32304, 
        "submitted_at"=>1258105888, 
        "mode" => "INTERACTIVE",
        "events"=>[
          {
            :type=>"REDUCE_RESERVATION_WALLTIME", 
            :created_at=>1258106496, 
            :uid=>2934161, 
            :to_check=>"NO", 
            :description=>"Change walltime from 32400 to 32304"
          }
        ], 
        "uid"=>948870,
        "user_uid"=>"rchakode", 
        "types"=>["deploy"], 
        "queue"=>"default", 
        "assigned_nodes"=>["genepi-8.grenoble.grid5000.fr"], 
        "started_at"=>1258106496, 
        "scheduled_at"=>1258106496, 
        "directory" => "/home/grenoble/rchakode",
        "command" => "",
        "project" => "default",
        "properties"=>"(deploy = 'YES') AND desktop_computing = 'NO'",
        "state"=>"running"
      )
    end
    it "should export only non-null attributes" do
      job = Grid5000::Job.new(:uid => 123)
      job.to_hash.should == {"uid" => 123}
    end
    it "should return all the attributes given at creation in a hash" do
      @job.to_hash.should == {
        "walltime"=>32304, 
        "submitted_at"=>1258105888, 
        "mode" => "INTERACTIVE",
        "events"=>[{:type=>"REDUCE_RESERVATION_WALLTIME", :created_at=>1258106496, :uid=>2934161, :to_check=>"NO", :description=>"Change walltime from 32400 to 32304"}], 
        "uid"=>948870,
        "user_uid"=>"rchakode", 
        "types"=>["deploy"], 
        "queue"=>"default", 
        "assigned_nodes"=>["genepi-8.grenoble.grid5000.fr"], 
        "started_at"=>1258106496, 
        "scheduled_at"=>1258106496, 
        "directory" => "/home/grenoble/rchakode",
        "command" => "",
        "project" => "default",
        "properties"=>"(deploy = 'YES') AND desktop_computing = 'NO'",
        "state"=>"running"
      }
    end
    it "should export to a hash structure valid for submitting a job to the oarapi" do
      reservation = Time.parse("2009-11-10 15:54:56Z")
      job = Grid5000::Job.new(:resources => "/nodes=1", :reservation => reservation, :command => "id", :types => ["deploy", "idempotent"], :walltime => 3600, :checkpoint => 40)
      job.should be_valid
      job.to_hash(:destination => "oar-2.4-submission").should == {
        "script"=>"id", 
        "checkpoint"=>40, 
        "walltime"=>3600, 
        "reservation"=>"2009-11-10 15:54:56", 
        "resource"=>"/nodes=1", 
        "type"=>["deploy", "idempotent"]
      }
    end
    it "should not export the type or reservation attribute if nil or empty" do
      reservation = Time.parse("2009-11-10 14:54:56Z")
      job = Grid5000::Job.new(:resources => "/nodes=1", :reservation => nil, :command => "id", :types => nil, :walltime => 3600, :checkpoint => 40)
      job.should be_valid
      job.to_hash(:destination => "oar-2.4-submission").should == {
        "script"=>"id", 
        "checkpoint"=>40, 
        "walltime"=>3600, 
        "resource"=>"/nodes=1"
      }
    end

    # abasu bug ref. 7360 - added test for import job_key_from_file --- 29.11.2016
    it "should copy import-job-key-from-file to a hash structure" do
      reservation = Time.parse("2009-11-10 15:54:56Z")
      job = Grid5000::Job.new(:resources => "/nodes=1", :reservation => reservation, :command => "id", :types => ["deploy", "idempotent"], :walltime => 3600, :checkpoint => 40, :'import-job-key-from-file' => "file://abcd")
      job.should be_valid
      job.to_hash(:destination => "oar-2.4-submission").should == {
        "script"=>"id", 
        "checkpoint"=>40, 
        "walltime"=>3600, 
        "reservation"=>"2009-11-10 15:54:56",
        "resource"=>"/nodes=1", 
        "type"=>["deploy", "idempotent"],
        "import-job-key-from-file"=> "file://abcd"
      }
    end # it "should copy import-job-key-from-file to a hash structure" do
  end
  
  describe "Creating for future submission" do
    before do
      @at = (Time.now+3600).to_i
      @valid_properties = {:resources => '/nodes=1', :reservation => @at, :walltime => 3600, :command => "id", :directory => '/home/crohr'}
    end
    it "should correctly define the required entries for a job to be submitted" do
      job = Grid5000::Job.new(@valid_properties)
      job.should be_valid
      job.resources.should == '/nodes=1'
      job.reservation.should == @at
      job.walltime.should == 3600
      job.command.should == 'id'
      job.directory.should == '/home/crohr'
      job.types.should == nil
    end
    it "should be valid if the reservation property is a Time" do
      job = Grid5000::Job.new(@valid_properties.merge(:reservation => Time.at(@at)))
      job.should be_valid
      job.reservation.should == @at
    end
    it "should be valid if the reservation property is a parseable date" do
      job = Grid5000::Job.new(@valid_properties.merge(:reservation => "2009/11/10 15:45:00 GMT+0100"))
      job.should be_valid
      job.reservation.should == Time.parse("2009/11/10 15:45:00 GMT+0100").to_i
    end
    it "should should be valid if no command is passed, but this is a reservation" do
      job = Grid5000::Job.new(@valid_properties.merge(:command => ""))
      job.should be_valid
      job = Grid5000::Job.new(@valid_properties.merge(:command => nil))
      job.should be_valid
    end
    it "should not be valid if there is nothing to do on launch, and this is a submission" do
      job = Grid5000::Job.new(@valid_properties.merge(:command => "", :reservation => nil))
      job.should_not be_valid
      job.errors.first.should == "you must give a :command to execute on launch"
      job = Grid5000::Job.new(@valid_properties.merge(:command => nil, :reservation => nil))
      job.should_not be_valid
      job.errors.first.should == "you must give a :command to execute on launch"
    end
    it "should correctly export the property attribute, if specified" do
      job = Grid5000::Job.new(@valid_properties.merge(:properties => "cluster='genepi'", :queue => "admin"))
      job.properties.should == "cluster='genepi'"
      job.queue.should == "admin"
      job.to_hash(:destination => "oar-2.4-submission").values_at('property', 'queue').should == ["cluster='genepi'", "admin"]
    end
    it "should correctly export the std* attributes, if specified" do
      job = Grid5000::Job.new(@valid_properties.merge(:stdout => "/home/crohr/stdout", :stderr => "/home/crohr/stderr"))
      job.stdout.should == "/home/crohr/stdout"
      job.stderr.should == "/home/crohr/stderr"
      job.to_hash(:destination => "oar-2.4-submission").values_at('stdout', 'stderr').should == ["/home/crohr/stdout", "/home/crohr/stderr"]
    end
  end
  
end
