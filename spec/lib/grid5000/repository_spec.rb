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
    @latest_commit = "8a562420c9a659256eeaafcfd89dfa917b5fb4d0"
  end

  it "should instantiate a new repository object with the correct settings" do
    repo = Grid5000::Repository.new(
      @repository_path,
      @repository_path_prefix
    )
    expect(repo.repository_path).to eq(@repository_path)
    expect(repo.repository_path_prefix).to eq(@repository_path_prefix)
  end

  it "should raise an error if the repository_path is incorrect" do
    expect(lambda{
      repo = Grid5000::Repository.new(
        "/does/not/exist",
        @repository_path_prefix
      )
    }).to raise_error(Grit::NoSuchPathError)
  end

  describe "with a working repository" do
    before do
      @repository = Grid5000::Repository.new(
        @repository_path,
        @repository_path_prefix
      )
    end

    describe "find" do
      it "should find / element" do
        object=@repository.find('grid5000')
        expect(object).to_not be_nil
        expect(object['version']).to eq @latest_commit
      end

      it "should return an exception if Grit::Git::GitTimeout is raised" do
        expect(@repository).to receive(:find_commit_for).and_raise(Grit::Git::GitTimeout)
        object=@repository.find('grid5000')
        expect(object).to be_an(Exception)
      end
    end
    describe "finding a specific version" do
      it "should return the latest commit of master if no specific version is given" do
        commit = @repository.find_commit_for(:version => nil)
        expect(commit.id).to eq(@latest_commit)
      end

      it "should find the commit associated with the given version [version=DATE] 1/2" do
        date = Time.parse("2009-03-13 17:24:20 +0100")
        commit = @repository.find_commit_for(:version => date.to_i)
        expect(commit.id).to eq("b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4")
      end

      it "should find the commit associated with the given version [version=DATE] 2/2" do
        date = Time.parse("2009-03-13 17:24:47 +0100")
        commit = @repository.find_commit_for(:version => date.to_i)
        expect(commit.id).to eq("e07895a4b480aaa8e11c35549a97796dcc4a307d")
      end

      it "should find the commit associated with the given version [version=SHA]" do
        commit = @repository.find_commit_for(
          :version => "e07895a4b480aaa8e11c35549a97796dcc4a307d"
        )
        expect(commit.id).to eq("e07895a4b480aaa8e11c35549a97796dcc4a307d")
      end

      it "should return nil when asking for a version from a branch that does not exist" do
        date = Time.parse("Fri Mar 13 17:24:47 2009 +0100")
        commit = @repository.find_commit_for(
          :version => date.to_i,
          :branch => "doesnotexist"
        )
        expect(commit).to be_nil
      end

      it "should return nil if the request version cannot be found" do
        commit = @repository.find_commit_for(
          :version => "aaa895a4b480aaa8e11c35549a97796dcc4a307d",
          :branch => "master"
        )
        expect(commit).to be_nil
      end

    end # describe "finding a specific version"

    describe "finding a specific object" do
      before do
        @commit = @repository.find_commit_for(:branch => 'master')
      end

      it "should find a tree object" do
        object = @repository.find_object_at(
          @repository.full_path('grid5000'), @commit)
        expect(object).to be_a(Grit::Tree)
      end

      it "should find a relative object (symlink)" do
        relative_to=@repository.full_path(
          'grid5000/sites/rennes/environments/sid-x64-base-1.0.json'
        )
        object = @repository.find_object_at(
          '../../../../grid5000/environments/sid-x64-base-1.0.json',
          @commit,
          relative_to)
        expect(object).to be_a(Grit::Blob)
        expect(object.data).to match /kernel/
      end

      it "should find a blob" do
        object = @repository.find_object_at(
          @repository.full_path(
            'grid5000/environments/sid-x64-base-1.0.json'
          ),
          @commit
        )
        expect(object).to be_a(Grit::Blob)
        expect(object.data).to match /kernel/
      end

      it "should return nil if the object cannot be found" do
        object = @repository.find_object_at(
          @repository.full_path('grid5000/does/not/exist'),
          @commit
        )
        expect(object).to be_nil
      end
    end # describe "finding a specific object"

    describe "expanding an object" do
      it "should expand a tree of blobs into a collection" do
        result = @repository.find(
          "grid5000/sites/bordeaux/clusters/bordemer/nodes"
        )
        expect(result).not_to be_nil
        # bordemer_nodes = object.expand
        expect(result["total"]).to eq(48)
        expect(result["items"].map{|i| i['uid']}.first).to eq( "bordemer-1")
      end
      it "should expand a tree of trees into a collection [sites]" do
        result = @repository.find(
          "grid5000/sites"
        )
        expect(result["items"].map{|i|
          i['uid']
        }).to eq(['bordeaux', 'grenoble', 'nancy', 'rennes'])
        expect(result["total"]).to eq(4)
        expect(result["offset"]).to eq(0)
      end
      it "should expand a tree of trees into a collection [environments]" do
        result = @repository.find(
          "grid5000/sites/rennes/environments"
        )
        expect(result["items"].map{|i|
          i['uid']
        }).to eq(["sid-x64-base-1.0"])
      end
      it "should expand a tree of blobs and trees into a resource hash resulting from the agregation of the blob's contents only" do
        result = @repository.find(
          "grid5000"
        )
        expect(result['uid']).to eq('grid5000')
        expect(result['sites']).to be_nil
      end
      it "should return the blob's content if the object is a blob" do
        result = @repository.find(
          "grid5000/sites/bordeaux/clusters/bordemer/nodes/bordemer-1"
        )
        expect(result['uid']).to eq('bordemer-1')
      end
      it "should correctly expand a symlink" do
        result = @repository.find(
          "grid5000/sites/bordeaux/environments/sid-x64-base-1.0"
        )
        expect(result).not_to be_nil
        expect(result['uid']).to eq('sid-x64-base-1.0')
      end
    end # describe "expanding an object"

    describe "versions_for" do
      it "find the versions for a resource" do
        # abasu - 24.10.2016 - update "total" value from 8 to 10
        expect(@repository.versions_for("grid5000/sites")["total"]).to eq(10)
      end
      it "should return an empty list if the resource does not exist" do
        expect(@repository.versions_for("grid5000/doesnotexist")).to eq({"total"=>0, "offset"=>0, "items"=>[]})
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
