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

module OAR
  class Resource < Base
    # `available_upto` value for which an 'absent' resource is considered to
    # be in the standby state.
    STANDBY_AVAILABLE_UPTO = 2147483646

    set_table_name "resources"
    set_primary_key :resource_id
    # disable inheritance guessed by Rails because of the "type" column.
    set_inheritance_column :_type_disabled

    QUERY_ASSIGNED_RESOURCES = "SELECT moldable_job_id, resource_id FROM %TABLE% WHERE moldable_job_id IN (%MOLDABLE_IDS%)"

    def dead?
      state && state == "dead"
    end

    def state
      value = read_attribute(:state)
      value.downcase! unless value.nil?
      value
    end

    class << self
      # Returns the status of all resources, indexed by the network address.
      # So, it returns only one entry per node, not per core.
      #
      # Returns a hash of the following format:
      #
      #   {
      #     'resource-network-address' => {
      #       :soft => "free|busy|besteffort|unknown",
      #       :hard => "dead|alive|absent|suspected|standby",
      #       :reservations => [...]
      #     },
      #     {...}
      #   }
      #
      def status(options = {})
        result = {}

        include_comment = columns.find{|c| c.name == "comment"}

        resources = Resource.select(
          "resource_id, network_address, state, available_upto#{include_comment ? ", comment" : ""}"
        )

        resources = resources.where(
          :cluster => options[:clusters]
        ) unless options[:clusters].blank?
        resources = resources.index_by(&:resource_id)

        active_jobs_by_moldable_id = {}
        Job.expanded.active.
          find(:all, :include => [:job_types]).
          each{|job|
          active_jobs_by_moldable_id[job.moldable_id] = {
            :resources => Set.new,
            :job => job
          }
        }
        
        # if there are jobs
        if active_jobs_by_moldable_id.length > 0
          moldable_ids = active_jobs_by_moldable_id.keys.
            map{|moldable_id| "'#{moldable_id}'"}.join(",")

          # get all resources assigned to these jobs
          %w{assigned_resources gantt_jobs_resources}.each do |table|
            self.connection.execute(
              QUERY_ASSIGNED_RESOURCES.gsub(
                /%TABLE%/, table
              ).gsub(
                /%MOLDABLE_IDS%/, moldable_ids
              )
            ).each do |(moldable_job_id, resource_id)|
              resource_id = resource_id.to_i

              active_jobs_by_moldable_id[moldable_job_id][:resources].
                add(resource_id)
            end
          end
        end

        active_jobs_by_moldable_id.each do |moldable_id, h|
          current = h[:job].running?

          h[:resources].each do |resource_id|
            resource = resources[resource_id]
            # The resource does not belong to a valid cluster.
            next if resource.nil?

            result[resource.network_address] ||= initial_status_for(resource)
            if current
              result[resource.network_address][:soft] = if h[:job].besteffort?
                "besteffort"
              else
                "busy"
              end
            end

            # Do not include events
            # (otherwise the Set does not work with nested hash)
            result[resource.network_address][:reservations].add(
              h[:job].to_reservation(:without => :events)
            )
          end
        end

        # fallback for resources without jobs
        resources.each do |resource_id, resource|
          result[resource.network_address] ||= initial_status_for(resource)
        end

        result
      end # def status

      # Returns the initial status hash for a resource.
      def initial_status_for(resource)
        hard = resource.state
        # Check if resource is in standby state
        if hard == 'absent' && resource.available_upto && resource.available_upto == STANDBY_AVAILABLE_UPTO
          hard = 'standby'
        end
        h = {
          :hard => hard,
          :soft => resource.dead? ? "unknown" : "free",
          :reservations => Set.new
        }
        h[:comment] = resource.comment if resource.respond_to?(:comment)
        h
      end
    end # class << self

  end



end
