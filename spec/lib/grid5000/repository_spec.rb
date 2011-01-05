require 'spec_helper'

describe Grid5000::Repository do
  before(:all) do
    @repository_path_prefix = "data"
    @latest_commit = "5b02702daa827f7e39ebf7396af26735c9d2aacd"
    # INIT TESTING GIT REPOSITORY
    @repository_path = File.expand_path(
      '../../../fixtures/reference-repository',
      __FILE__
    )
    if File.exist?( File.join(@repository_path, 'git.rename') )
      cmd = "mv #{File.join(@repository_path, 'git.rename')} #{File.join(@repository_path, '.git')}"
      system cmd
    end
  end
  
  after(:all) do
    if File.exist?( File.join(@repository_path, '.git') )
      system "mv #{File.join(@repository_path, '.git')} #{File.join(@repository_path, 'git.rename')}"
    end
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
        date = Time.parse("Fri Mar 13 17:24:20 2009 +0100")
        commit = @repository.find_commit_for(:version => date.to_i)
        commit.id.should == "b00bd30bf69c322ffe9aca7a9f6e3be0f29e20f4"
      end
      
      it "should find the commit associated with the given version [version=DATE] 2/2" do      
        date = Time.parse("Fri Mar 13 17:24:47 2009 +0100")
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
        object = @repository.find_object_at('grid5000', @commit)
        object.should be_a(Grit::Tree)
      end
      
      it "should find a relative object (symlink)" do
        relative_to='grid5000/sites/rennes/environments/sid-x64-base-1.0.json'
        object = @repository.find_object_at(
          '../../../../grid5000/environments/sid-x64-base-1.0.json', 
          @commit, 
          relative_to)
        object.should be_a(Grit::Blob)
        object.data.should =~ /kernel/
      end
      
      it "should find a blob" do
        object = @repository.find_object_at(
          'grid5000/environments/sid-x64-base-1.0.json', 
          @commit
        )
        object.should be_a(Grit::Blob)
        object.data.should =~ /kernel/
      end
      
      it "should return nil if the object cannot be found" do
        object = @repository.find_object_at(
          'grid5000/does/not/exist', 
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
      it "should expand a tree of trees into a collection" do
        result = @repository.find(
          "grid5000/sites"
        )
        result["items"].map{|i| 
          i['uid']}
        .should == ['bordeaux', 'grenoble', 'rennes']
        result["total"].should == 3
        result["offset"].should == 0
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
        EM.synchrony do
          result = EM::Synchrony.sync @repository.async_find(
            "grid5000/sites/bordeaux/clusters/bordemer/nodes/bordemer-1"
          )
          EM.stop
        end
      end
    end
  end # describe "with a working repository"
  
  
  
  # it "should description" do
  #   object = repository.async_find(sha, :branch => "master") do |hash, uri|
  #     hash['links'] = links_for(hash, uri)
  #   end
  #   
  # end
end
