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

describe Grid5000::Repository do
  before do
    # abasu - 03.03.2016 - updated value from 070663579dafada27e078f468614f85a62cf2992
    @latest_commit = "2ed3470e0881a22baa43718e62098a0b8dee1e4b"
  end
  
  it "should instantiate a new repository object with the correct settings" do
    repo = Grid5000::Repository.new(
      @repository_path, 
      @repository_path_prefix
    )
    repo.repository_path.should == @repository_path
    repo.repository_path_prefix.should == @repository_path_prefix
  end
  
  it "should raise an error if the repository_path is incorrect" do
    lambda{
      repo = Grid5000::Repository.new(
        "/does/not/exist", 
        @repository_path_prefix
      )
    }.should raise_error(Grit::NoSuchPathError)
  end
  
  describe "with a working repository" do
    before do
      @repository = Grid5000::Repository.new(
        @repository_path, 
        @repository_path_prefix
      )
    end
    
    describe "finding a specific version" do
      it "should return the latest commit of master if no specific version is given" do
        commit = @repository.find_commit_for(:version => nil)
        commit.id.should == @latest_commit
      end
      
      it "should find the commit associated with the given version [version=DATE] 1/2" do      
        date = Time.parse("2009-03-13 17:24:20 +0100")
        commit = @repository.find_commit_for(:version => date.to_i)
        commit.id.should == "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      end
      
      it "should find the commit associated with the given version [version=DATE] 2/2" do      
        date = Time.parse("2009-03-13 17:24:47 +0100")
        commit = @repository.find_commit_for(:version => date.to_i)
        commit.id.should == "e07895a4b480aaa8e11c35549a97796dcc4a307d"
      end
      
      it "should find the commit associated with the given version [version=SHA]" do
        commit = @repository.find_commit_for(
          :version => "e07895a4b480aaa8e11c35549a97796dcc4a307d"
        )
        commit.id.should == "e07895a4b480aaa8e11c35549a97796dcc4a307d"
      end
      
      it "should return nil when asking for a version from a branch that does not exist" do
        date = Time.parse("Fri Mar 13 17:24:47 2009 +0100")
        commit = @repository.find_commit_for(
          :version => date.to_i, 
          :branch => "doesnotexist"
        )
        commit.should be_nil
      end
      
      it "should return nil if the request version cannot be found" do
        commit = @repository.find_commit_for(
          :version => "aaa895a4b480aaa8e11c35549a97796dcc4a307d", 
          :branch => "master"
        )
        commit.should be_nil
      end
  
    end # describe "finding a specific version"
    
    describe "finding a specific object" do
      before do
        @commit = @repository.find_commit_for(:branch => 'master')
      end
      
      it "should find a tree object" do
        object = @repository.find_object_at(
          @repository.full_path('grid5000'), @commit)
        object.should be_a(Grit::Tree)
      end
      
      it "should find a relative object (symlink)" do
        relative_to=@repository.full_path(
          'grid5000/sites/rennes/environments/sid-x64-base-1.0.json'
        )
        object = @repository.find_object_at(
          '../../../../grid5000/environments/sid-x64-base-1.0.json', 
          @commit, 
          relative_to)
        object.should be_a(Grit::Blob)
        object.data.should =~ /kernel/
      end
      
      it "should find a blob" do
        object = @repository.find_object_at(
          @repository.full_path(
            'grid5000/environments/sid-x64-base-1.0.json'
          ), 
          @commit
        )
        object.should be_a(Grit::Blob)
        object.data.should =~ /kernel/
      end
      
      it "should return nil if the object cannot be found" do
        object = @repository.find_object_at(
          @repository.full_path('grid5000/does/not/exist'), 
          @commit
        )
        object.should be_nil
      end
    end # describe "finding a specific object"
    
    describe "expanding an object" do
      it "should expand a tree of blobs into a collection" do
        result = @repository.find(
          "grid5000/sites/bordeaux/clusters/bordemer/nodes"
        )
        result.should_not be_nil
        # bordemer_nodes = object.expand
        result["total"].should == 48
        result["items"].map{|i| i['uid']}.first.should ==  "bordemer-1"
      end
      it "should expand a tree of trees into a collection [sites]" do
        result = @repository.find(
          "grid5000/sites"
        )
        result["items"].map{|i| 
          i['uid']
        # abasu - 08.01.2016 - added to list 'nancy' and updated "total" from 3 to 4
        }.should == ['bordeaux', 'grenoble', 'nancy', 'rennes']
        result["total"].should == 4
        result["offset"].should == 0
      end
      it "should expand a tree of trees into a collection [environments]" do
        result = @repository.find(
          "grid5000/sites/rennes/environments"
        )
        result["items"].map{|i| 
          i['uid']
        }.should == ["sid-x64-base-1.0"]
      end
      it "should expand a tree of blobs and trees into a resource hash resulting from the agregation of the blob's contents only" do
        result = @repository.find(
          "grid5000"
        )
        result['uid'].should == 'grid5000'
        result['sites'].should be_nil
      end
      it "should return the blob's content if the object is a blob" do
        result = @repository.find(
          "grid5000/sites/bordeaux/clusters/bordemer/nodes/bordemer-1"
        )
        result['uid'].should == 'bordemer-1'
      end
      it "should correctly expand a symlink" do
        result = @repository.find(
          "grid5000/sites/bordeaux/environments/sid-x64-base-1.0"
        )
        result.should_not be_nil
        result['uid'].should == 'sid-x64-base-1.0'
      end
    end # describe "expanding an object"
    
    describe "async find" do
      it "should defer the execution and return the result" do
        result = EM::Synchrony.sync @repository.async_find(
          "grid5000/sites/bordeaux/clusters/bordemer/nodes/bordemer-1"
        )
      end
    end
    
    describe "versions_for" do
      it "find the versions for a resource" do
        # abasu - 24.10.2016 - update "total" value from 8 to 10
        @repository.versions_for("grid5000/sites")["total"].should == 10
      end
      it "should return an empty list if the resource does not exist" do
        @repository.versions_for("grid5000/doesnotexist").should == {"total"=>0, "offset"=>0, "items"=>[]}
      end
    end # describe versions_for
  end # describe "with a working repository"
  
  
  
  # it "should description" do
  #   object = repository.async_find(sha, :branch => "master") do |hash, uri|
  #     hash['links'] = links_for(hash, uri)
  #   end
  #   
  # end
end
