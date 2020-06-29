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

require 'json'
require 'logger'
require 'rugged'

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
      @instance = Rugged::Repository.new(repository_path)
    end

    def find(path, options = {})
      logger.info "    Repository path = #{repository_path.inspect}"
      logger.info "    path = #{path.inspect}, options = #{options.inspect}"
      path = full_path(path)
      @commit = nil
      begin
        @commit = find_commit_for(options)
        logger.info "    commit = #{@commit.inspect}"
        return nil if @commit.nil?
        object = find_object_at(path, @commit)
        logger.debug "    object = #{object.inspect}"
        return nil if object.nil?
      rescue => e
        logger.debug "#{Time.now}: Got a Rugged exception #{e}"
        return e
      end

      result = expand_object(object, path, @commit)
      result
    end

    def full_path(path)
      File.join(repository_path_prefix, path)
    end

    def expand_object(hash_object, path, commit)
      return nil if hash_object.nil?

      object = instance.lookup(hash_object[:oid])

      # If it's a symlink
      if hash_object[:filemode] == 40960
        hash_object = find_object_at(object.content, commit, relative_to=path)
        object = instance.lookup(hash_object[:oid])
      end

      case object.type
      when :blob
        @subresources = []
        JSON.parse(object.content).merge("version" => commit.oid)
      when :tree
        groups = object.each.group_by{|content| content[:type]}
        blobs, trees = [groups[:blob] || [], groups[:tree] || []]

        # select only json files
        blobs = blobs.select{|blob| File.extname(blob[:name]) == '.json'}
        if (blobs.size > 0 && trees.size > 0) # item
          blobs.inject({'subresources' => trees}) do |accu, blob|
            content = expand_object(
              blob,
              File.join(path, blob[:name].gsub(".json", "")),
              commit
            )
            accu.merge(content)
          end
        else # collection
          items = object.map do |object|
            content = expand_object(
              object,
              File.join(path, object[:name].gsub(".json", "")),
              commit
            )
          end
          result = {
            "total" => items.length,
            "offset" => 0,
            "items" => items,
            "version" => commit.oid
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
        instance.branches[branch].target
      elsif version.to_s.length == 40 # SHA
        instance.lookup(version)
      else
        # version should be a date, get the closest commit
        date = version.to_i

        return nil if instance.branches[branch].nil?

        walker = Rugged::Walker.new(instance)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(instance.branches[branch].target.oid)

        commits = walker.select do |commit|
          commit.epoch_time <= date
        end
        commits.map! { |commit| commit.oid }

        sha = commits.first
        find_commit_for(options.merge(:version => sha))
      end
    rescue Rugged::OdbError
      nil
    end

    def find_object_at(path, commit, relative_to = nil)
      path = relative_path_to(path, relative_to) unless relative_to.nil?

      begin
        object = commit.tree.path(path)
      rescue Rugged::TreeError
        begin
          object = commit.tree.path(path + '.json')
        rescue Rugged::TreeError
          nil
        end
      end
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

    def versions_for(path, options = {})
      branch, offset, limit = options.values_at(:branch, :offset, :limit)
      branch ||= 'master'
      offset = (offset || 0).to_i
      limit = (limit || 100).to_i
      path = full_path(path)
      commits = []

      if instance.branches.exist?(branch)
        oid = instance.branches[branch].target.oid
      else
        begin
          if instance.exists?(branch)
            oid = instance.lookup(branch).oid
          else
            oid = nil
          end
        rescue
          oid = nil
        end
      end

      if oid
        walker = Rugged::Walker.new(instance)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(oid)

        commits = walker.select do |commit|
          commit.diff(paths: [path]).size > 0
        end

        if commits.empty?
          commits = walker.select do |commit|
            commit.diff(paths: [path + '.json']).size > 0
          end
        end
      end

      {
        "total" => commits.length,
        "offset" => offset,
        "items" => commits.slice(offset, limit)
      }
    end
  end

end # module Grid5000
