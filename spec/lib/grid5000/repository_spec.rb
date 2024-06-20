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
  it 'should instantiate a new repository object with the correct settings' do
    repo = Grid5000::Repository.new(
      @repository_path,
      @repository_path_prefix
    )
    expect(repo.repository_path).to eq(@repository_path)
    expect(repo.repository_path_prefix).to eq(@repository_path_prefix)
  end

  it 'should raise an error if the repository_path is incorrect' do
    expect { Grid5000::Repository.new('/does/not/exist', @repository_path_prefix) }.to raise_error(Rugged::OSError)
  end

  describe 'with a working repository' do
    before do
      @repository = Grid5000::Repository.new(
        @repository_path,
        @repository_path_prefix
      )
    end

    describe 'find' do
      it 'should find / element' do
        object = @repository.find_and_expand('grid5000')
        expect(object).to_not be_nil
        expect(object['version']).to eq @latest_commit
      end

      it 'should return an exception if Rugged::PathError is raised' do
        expect(@repository).to receive(:find).and_raise(Rugged::RepositoryError)
        object = @repository.find_and_expand('grid5000')
        expect(object).to be_an(Exception)
      end
    end

    describe 'finding a specific version' do
      it 'should return the latest commit of master if no specific version is given' do
        commit = @repository.find_commit_for('data', version: nil)
        expect(commit.oid).to eq(@latest_commit)
      end

      it 'should find the commit associated with the given timestamp [timestamp=TS] 1/2' do
        date = Time.parse('2009-03-13 17:24:20 +0100')
        commit = @repository.find_commit_for(nil, timestamp: date.to_i)
        expect(commit.oid).to eq('464e6bfc0195deeb4e93f61229857e1e8032bd6b')
      end

      it 'should find the commit associated with the given date [date=DATE] 2/2' do
        date = '2009-03-13 17:24:47 +0100'
        commit = @repository.find_commit_for(nil, date: date)
        expect(commit.oid).to eq('464e6bfc0195deeb4e93f61229857e1e8032bd6b')
      end

      it 'should find the commit associated with the given version [version=SHA]' do
        commit = @repository.find_commit_for(
          nil,
          version: '464e6bfc0195deeb4e93f61229857e1e8032bd6b'
        )
        expect(commit.oid).to eq('464e6bfc0195deeb4e93f61229857e1e8032bd6b')
      end

      it 'should return Errors::BranchNotFound when asking for a version from a branch that does not exist' do
        date = Time.parse('Fri Mar 13 17:24:47 2009 +0100')
        expect { @repository.find_commit_for(
          nil,
          timestamp: date.to_i,
          branch: 'doesnotexist'
        ) }.to raise_error(Grid5000::Errors::Repository::BranchNotFound)
      end

      it 'should return Errors::CommitNotfound if the request version cannot be found' do
        expect { @repository.find_commit_for(
          nil,
          version: 'aaa895a4b480aaa8e11c35549a97796dcc4a307d',
          branch: 'master'
        ) }.to raise_error(Grid5000::Errors::Repository::CommitNotFound)
      end
    end # describe "finding a specific version"

    describe 'finding a specific object' do
      before do
        @commit = @repository.find_commit_for('data', branch: 'master')
      end

      it 'should find a tree object' do
        hash_object = @repository.find_object_at(
          @repository.full_path('grid5000'), @commit
        )

        object = @repository.instance.lookup(hash_object[:oid])
        expect(object).to be_a(Rugged::Tree)
      end

      it 'should find a relative object (symlink)' do
        relative_to = @repository.full_path(
          'symlink/sites/nancy/nancy.json'
        )
        hash_object = @repository.find_object_at(
          '../../../grid5000/sites/nancy/nancy.json',
          @commit,
          relative_to
        )

        object = @repository.instance.lookup(hash_object[:oid])
        expect(object).to be_a(Rugged::Blob)
        expect(object.content).to match(/location/)
      end

      it 'should find a blob' do
        hash_object = @repository.find_object_at(
          @repository.full_path(
            'grid5000/sites/nancy/nancy.json'
          ),
          @commit
        )

        object = @repository.instance.lookup(hash_object[:oid])
        expect(object).to be_a(Rugged::Blob)
        expect(object.content).to match(/location/)
      end

      it 'should return nil if the object cannot be found' do
        object = @repository.find_object_at(
          @repository.full_path('grid5000/does/not/exist'),
          @commit
        )
        expect(object).to be_nil
      end
    end # describe "finding a specific object"

    describe 'expanding an object' do
      it 'should expand a tree of blobs into a collection' do
        result = @repository.find_and_expand(
          'grid5000/sites/grenoble/clusters/dahu/nodes'
        )
        expect(result).not_to be_nil
        # dahu_nodes = object.expand
        expect(result['total']).to eq(32)
        expect(result['items'].map { |i| i['uid'] }.first).to eq('dahu-1')
      end
      it 'should not deep expand when path is a end of hierarchy' do
        result = @repository.find_and_expand(
          'grid5000/sites/grenoble/clusters/dahu/nodes/dahu-1',
          {deep: true}
        )
        expect(result).not_to be_nil
        expect(result['uid']).to eq('dahu-1')
      end
      it 'should expand a tree of trees into a collection [sites]' do
        result = @repository.find_and_expand(
          'grid5000/sites'
        )
        expect(result['items'].map do |i|
          i['uid']
        end).to eq(%w[grenoble lille luxembourg lyon nancy nantes rennes sophia])
        expect(result['total']).to eq(8)
        expect(result['offset']).to eq(0)
      end
      it "should expand a tree of blobs and trees into a resource hash resulting from the agregation of the blob's contents only" do
        result = @repository.find_and_expand(
          'grid5000'
        )
        expect(result['uid']).to eq('grid5000')
        expect(result['sites']).to be_nil
      end
      it "should return the blob's content if the object is a blob" do
        result = @repository.find_and_expand(
          'grid5000/sites/grenoble/clusters/dahu/nodes/dahu-1'
        )
        expect(result['uid']).to eq('dahu-1')
      end
      # Hack to test symlink. Here srv-3 is a link to srv-2
      it 'should correctly expand a symlink' do
        result = @repository.find_and_expand(
          'grid5000/sites/nancy/servers/grcinq-srv-3.json'
        )
        expect(result).not_to be_nil
        expect(result['uid']).to eq('grcinq-srv-2')
      end
    end # describe "expanding an object"

    describe 'versions_for' do
      it 'find the versions for a resource' do
        expect(@repository.versions_for('grid5000/sites')['total']).to eq(3058)
      end
      it 'should return an empty list if the resource does not exist' do
        expect(@repository.versions_for('grid5000/doesnotexist')).to eq({ 'total' => 0, 'offset' => 0, 'items' => [] })
      end
    end # describe versions_for
  end # describe "with a working repository"
end
