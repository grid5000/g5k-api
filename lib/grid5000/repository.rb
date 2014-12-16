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

require 'grid5000/extensions/grit'
require 'json'
require 'logger'

module Grid5000
  class Repository
    attr_reader :repository_path, :repository_path_prefix, :instance, :commit, :logger

    def initialize(repository_path, repository_path_prefix = nil, logger = nil)
      @commit = nil
      @reloading = false
      @repository_path_prefix = repository_path_prefix ? repository_path_prefix.gsub(/^\//,'') : repository_path_prefix
      @repository_path = File.expand_path repository_path
      if logger
        @logger = logger
      else
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::WARN
      end
      @instance = Grit::Repo.new(repository_path)
    end

    def find(path, options = {})
      logger.info "Repository path = #{repository_path.inspect}"
      logger.info "path = #{path.inspect}, options = #{options.inspect}"
      path = full_path(path)
      @commit = nil
      @commit = find_commit_for(options)
      logger.info "commit = #{@commit.inspect}"
      return nil if @commit.nil?
      object = find_object_at(path, @commit)
      logger.debug "object = #{object.inspect}"
      return nil if object.nil?
      result = expand_object(object, path, @commit)
      result
    end

    def full_path(path)
      File.join(repository_path_prefix, path)
    end

    def expand_object(object, path, commit)
      return nil if object.nil?

      if object.mode == "120000"
        object = find_object_at(object.data, commit, relative_to=path)
      end

      case object
      when Grit::Blob
        @subresources = []
        JSON.parse(object.data).merge("version" => commit.id)
      when Grit::Tree
        groups = object.contents.group_by{|content| content.class}
        blobs, trees = [groups[Grit::Blob] || [], groups[Grit::Tree] || []]
        # select only json files
        blobs = blobs.select{|blob| File.extname(blob.name) == '.json'}
        if (blobs.size > 0 && trees.size > 0) # item
          blobs.inject({'subresources' => trees}) do |accu, blob|
            content = expand_object(
              blob,
              File.join(path, blob.name.gsub(".json", "")),
              commit
            )
            accu.merge(content)
          end
        else # collection
          items = object.contents.map do |object|
            content = expand_object(
              object,
              File.join(path, object.name.gsub(".json", "")),
              commit
            )
          end
          result = {
            "total" => items.length,
            "offset" => 0,
            "items" => items,
            "version" => commit.id
          }
          result
        end
      else
        nil
      end
    end

    def find_commit_for(options = {})
      options[:branch] ||= 'master'
      version, branch = options.values_at(:version, :branch)
      if version.nil?
        instance.commits(branch)[0]
      elsif version.to_s.length == 40 # SHA
        instance.commit(version)
      else
        # version should be a date, get the closest commit
        date = Time.at(version.to_i).strftime("%Y-%m-%d %H:%M:%S")
        sha = instance.git.rev_list({
          :pretty => :raw, :until => date
        }, branch)
        sha = sha.split("\n")[0]
        find_commit_for(options.merge(:version => sha))
      end
    rescue Grit::GitRuby::Repository::NoSuchShaFound => e
      nil
    end

    def find_object_at(path, commit, relative_to = nil)
      path = relative_path_to(path, relative_to) unless relative_to.nil?
      object = commit.tree/path || commit.tree/(path+".json")
    end

    # Return the physical path within the repository
    # Takes care of symbolic links
    def relative_path_to(path, relative_to = nil)
      if relative_to
        path = File.expand_path(
          # symlink, e.g. "../../../../grid5000/environments/etch-x64-base-1.0.json"
          path,
          # e.g. : File.join("/",  File.dirname("grid5000/sites/rennes/environments/etch-x64-base-1.0"))
          File.join('/', File.dirname(relative_to))
        ).gsub(/^\//, "")
      end
      path
    end

    def async_find(*args)
      require 'eventmachine'
      self.extend(EventMachine::Deferrable)
      callback = proc { |result|
        set_deferred_status :succeeded, result
      }

      EM.defer(proc{
        result = find(*args)
      }, callback)
      self
    end

    def versions_for(path, options = {})
      branch, offset, limit = options.values_at(:branch, :offset, :limit)
      branch ||= 'master'
      offset = (offset || 0).to_i
      limit = (limit || 100).to_i
      path = full_path(path)
      commits = instance.log(
        branch,
        path
      )
      commits = instance.log(
        branch,
        path+".json"
      ) if commits.empty?
      {
        "total" => commits.length,
        "offset" => offset,
        "items" => commits.slice(offset, limit)
      }
    end

  end

end # module Grid5000
