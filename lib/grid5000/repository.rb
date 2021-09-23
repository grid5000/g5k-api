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
require 'hash'

module Grid5000
  class Repository
    attr_reader :repository_path, :repository_path_prefix, :instance, :commit, :logger

    def initialize(repository_path, repository_path_prefix = nil, logger = nil)
      @commit = nil
      @reloading = false
      @repository_path_prefix = repository_path_prefix ? repository_path_prefix.gsub(%r{^/}, '') : repository_path_prefix
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
        @commit = find_commit_for(path, options)
        return nil if @commit.nil?
        logger.info "    commit = #{@commit} {id: #{@commit.oid}, message: #{@commit.message.chomp}}"

        object = find_object_at(path, @commit)
        logger.debug "    object = #{object}"
        return nil if object.nil?
      rescue Rugged::Error => e
        logger.debug "#{Time.now}: Got a Rugged exception #{e}"
        return e
      end

      result = if options[:deep]
                 deep_expand(object, path, @commit)
               else
                 expand_object(object, path, @commit)
               end

      result
    end

    def full_path(path)
      File.join(repository_path_prefix, path)
    end

    def expand_object(hash_object, path, commit)
      return nil if hash_object.nil?

      object = instance.lookup(hash_object[:oid])

      # If it's a symlink
      if hash_object[:filemode] == 40_960
        hash_object = find_object_at(object.content, commit, path)
        object = instance.lookup(hash_object[:oid])
      end

      case object.type
      when :blob
        @subresources = []
        JSON.parse(object.content).merge('version' => commit.oid)
      when :tree
        groups = object.each.group_by { |content| content[:type] }
        blobs = groups[:blob] || []
        trees = groups[:tree] || []

        # select only json files
        blobs = blobs.select { |blob| File.extname(blob[:name]) == '.json' }
        if blobs.size > 0 && trees.size > 0 # item
          blobs.inject({ 'subresources' => trees }) do |accu, blob|
            content = expand_object(
              blob,
              File.join(path, blob[:name].gsub('.json', '')),
              commit
            )
            accu.merge(content)
          end
        else # collection
          items = object.map do |object_map|
            expand_object(
              object_map,
              File.join(path, object_map[:name].gsub('.json', '')),
              commit
            )
          end
          result = {
            'total' => items.length,
            'offset' => 0,
            'items' => items,
            'version' => commit.oid
          }
          result
        end
      end
    end

    def deep_expand(hash_object, path, commit)
      return nil if hash_object.nil?

      tree_object = instance.lookup(hash_object[:oid])

      # If it's a symlink
      if hash_object[:filemode] == 40_960
        hash_object = find_object_at(instance.lookup(entry[:oid]).content, commit, File.join(path, root, entry[:name]))
        tree_object = instance.lookup(hash_object[:oid])
      end

      deep_hash = {}
      flat_array = []
      sub_hash = {}
      last_root = nil
      tree_object.walk_blobs(:postorder) do |root, entry|
        next unless File.extname(entry[:name]) == '.json'

        # If it's a symlink
        if entry[:filemode] == 40960
          hash_object = find_object_at(instance.lookup(entry[:oid]).content, commit, File.join(path, root, entry[:name]))
          object = instance.lookup(hash_object[:oid])
        else
          object = instance.lookup(entry[:oid])
        end

        path_hierarchy = File.dirname("#{root}#{entry[:name]}").split('/')
        file_hash = JSON.parse(object.content)

        last_root = root unless last_root
        sub_hash = {} if last_root != root
        last_root = root

        path_hierarchy = [] if path_hierarchy == ['.']

        # If it's a node or a network_equipment, we want to return an Array of
        # Hashes
        #
        # This is also required when we want to return a list (for example a
        # list of servers) with no parent. This case happens for a deep view.
        if ['nodes', 'network_equipments', 'servers', 'pdus'].include?(path_hierarchy.last) ||
            (root.empty? && File.basename(entry[:name], '.json') != path.split('/').last)

          if path_hierarchy.empty?
            flat_array << file_hash
          else
            sub_hash[path_hierarchy.last] ||= []
            sub_hash[path_hierarchy.last] << file_hash
            merge_path_hierarchy = path_hierarchy - [path_hierarchy.last]
            deep_hash = deep_hash.deep_merge(Hash.from_array(merge_path_hierarchy, sub_hash))
          end
        else
          file_hash = Hash.from_array(path_hierarchy, file_hash)
          deep_hash = deep_hash.deep_merge(file_hash)
        end
      end

      data = deep_hash.empty? ? flat_array : deep_hash

      result = {
        "total" => data.length,
        "offset" => 0,
        "items" => rec_sort(data),
        "version" => commit.oid
      }
      result
    end

    def find_commit_for(path, options = {})
      # path parameter is only used when not requesting a specific version (commit)
      # or timestamp.
      options[:branch] ||= 'master'
      version, branch, timestamp, date = options.values_at(:version, :branch, :timestamp, :date)
      if version
        begin
          instance.lookup(version)
        rescue
          raise Errors::CommitNotFound.new(version)
        end
      elsif timestamp || date
        if timestamp
          ts = timestamp.to_i
        else
          ts = Time.parse(date).to_i
        end

        raise Errors::BranchNotFound.new(branch) if instance.branches[branch].nil?

        walker = Rugged::Walker.new(instance)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(instance.branches[branch].target.oid)

        commits = walker.select do |commit|
          commit.epoch_time <= ts
        end
        commits.map! { |commit| commit.oid }

        sha = commits.first
        find_commit_for(nil, options.merge(version: sha))
      else
        if path
          raise Errors::BranchNotFound.new(branch) unless instance.branches.exist?(branch)
          walker = Rugged::Walker.new(instance)
          walker.sorting(Rugged::SORT_DATE)
          walker.push(instance.branches[branch].target.oid)
          commit = nil
          walker.each do |c|
            if c.diff(paths: [path, "#{path}.json"]).size > 0
              commit = c
              break
            end
          end
          commit
        else
          instance.branches[branch].target
        end
      end
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

      object
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
        ).gsub(%r{^/}, '')
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

      oid = if instance.branches.exist?(branch)
              instance.branches[branch].target.oid
            else
              begin
                instance.exists?(branch)
              rescue
                raise Errors::RefNotFound.new(branch)
              end

              instance.lookup(branch).oid
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
        'total' => commits.length,
        'offset' => offset,
        'items' => commits.slice(offset, limit)
      }
    end
  end

  module Errors
    class RepositoryError < StandardError
    end

    class BranchNotFound < RepositoryError
      def initialize(branch = nil)
        if branch
          super("Branch '#{branch}' cannot be found.")
        else
          super('Branch cannot be found.')
        end
      end
    end

    class CommitNotFound < RepositoryError
      def initialize(commit = nil)
        if commit
          super("Commit '#{commit}' cannot be found.")
        else
          super('Commit cannot be found.')
        end
      end
    end

    class RefNotFound < RepositoryError
      def initialize(ref = nil)
        if ref
          super("Reference (branch or commit) '#{ref}' cannot be found.")
        else
          super('Reference (branch or commit) cannot be found.')
        end
      end
    end
  end
end # module Grid5000
