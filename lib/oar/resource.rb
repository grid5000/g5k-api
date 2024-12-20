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
    STANDBY_AVAILABLE_UPTO = 2_147_483_646

    self.table_name = 'resources'
    self.primary_key = :resource_id
    # disable inheritance guessed by Rails because of the "type" column.
    self.inheritance_column = :_type_disabled

    EXCLUDED_TYPES = ['storage', 'metroflux', 'kavlan-topo']

    QUERY_ASSIGNED_RESOURCES = 'SELECT moldable_job_id, resource_id FROM assigned_resources WHERE moldable_job_id IN (%MOLDABLE_IDS%)'.freeze
    QUERY_GANTT_JOBS_RESOURCES = 'SELECT moldable_job_id, resource_id FROM gantt_jobs_resources WHERE moldable_job_id IN (%MOLDABLE_IDS%)'.freeze
    def dead?
      state && state == 'dead'
    end

    def state
      value = read_attribute(:state)
      value&.downcase!
      value
    end

    def api_type
      Resource.api_type(type)
    end

    def api_name
      case type
      when 'default'
        network_address
      when 'disk'
        [disk.split('.').first, host].join('.')
      when /^(kavlan|kavlan-global|kavlan-local)$/
        vlan
      when 'subnet'
        subnet_address + '/' + subnet_prefix.to_s
      else
        resource_id
      end
    end

    class << self
      def api_type(oar_type)
        case oar_type
        when /^(kavlan|kavlan-global|kavlan-local)$/
          'vlans'
        when 'default'
          'nodes'
        else
          oar_type.pluralize
        end
      end

      def list_some(options)
        resources = Resource

        unless options[:network_address].blank?
          resources = resources.where(
            '"network_address" = ? OR "host" = ?', options[:network_address], options[:network_address]
          )
        end

        if options[:clusters].present?
          resources = resources.where(
            cluster: options[:clusters], type: options[:oar_types]
          ).or(resources.where(type: options[:oar_types], cluster: nil))
        else
          resources = resources.where(type: options[:oar_types])
        end

        resources
      end

      # Returns the status of all resources from the types requested,
      # indexed_by type
      # in addition to OAR's types, node is supported, where
      # the result is indexed by the network address when present.
      # So, it returns only one entry per node, not per core for resources
      # of type default.
      #
      # Returns a hash of the following format when called with types => ["node", "disk"]:
      #
      #   {
      #     "nodes" => {
      #       'resource-network-address' => {
      #         :soft => "free|busy|besteffort|unknown",
      #         :hard => "dead|alive|absent|suspected|standby",
      #         :reservations => [...]
      #       }, {...}
      #     }
      #     "disks" => {
      #       'disk.host => {
      #         :soft => "free|busy",
      #         :disk => disk identifier,
      #         :diskpath => disk path,
      #         :reservations => [...]
      #       }, {...}
      #     },
      #     {...}
      #   }

      def status(options = {})
        # Handle options

        #   No types requested implies default
        #   and default is returned as nodes
        options[:types] = ['node'] if options[:types].nil?
        options[:types].reject! { |t| EXCLUDED_TYPES.include?(t) }

        options[:oar_types] = options[:types]
        had_node = options[:oar_types].delete('node') == 'node'
        options[:oar_types].push('default') if had_node

        #   Control verbosity of result
        #   job_details controls whether future reservations
        #   of a given resources are returned
        include_details = options[:job_details] != 'no'

        # Build the list of resources for which status is requested
        resource_list = list_some(options)

        # Build the list of active jobs with the resources they use
        active_jobs = get_active_jobs_with_resources(options).values

        api_status = {}
        api_status_data = {} # used later to aggregate oar resource status date at api resource level

        # answer with some data for all requested types
        # even when no resources of that type can be found
        options[:oar_types].each do |oar_type|
          api_status[api_type(oar_type)] = {}
          api_status_data[api_type(oar_type)] = {}
        end

        resources = {}

        # Go though the list of resource (oar's definition) to
        # - index by resource_id (.index_by(&:resource_id))
        # - set the API status of resources (API's definition) with no jobs ;
        # - setup any data required to compute the API status when it depends on the
        #   status of multiple OAR resources (eg. nodes)
        resource_list.each do |resource|
          next if resource.nil?

          resources[resource.resource_id] = resource

          api_status[resource.api_type][resource.api_name] ||= initial_status_for(resource)

          api_status_data[resource.api_type][resource.api_name] ||= initial_status_data_for(resource, include_details)

          api_status_data[resource.api_type][resource.api_name] =
            update_with_resource(api_status_data[resource.api_type][resource.api_name],
                                 resource)
        end

        # Go through active jobs and update status data for all the
        # resources of the job
        active_jobs.each do |h|
          # prepare job description now, since it will be the same for each
          # resource of the job
          # For api_status hash table, do not include events
          # (otherwise the Set does not work with nested hash)
          job_for_api = nil
          job_for_api = h[:job].to_reservation(without: :events) if include_details

          h[:resources].each do |resource_id|
            resource = resources[resource_id]
            # The resource does not belong to the list of resources the caller is interested in.
            next if resource.nil?

            api_status_data[resource.api_type][resource.api_name] =
              update_with_job(resource.api_type,
                              api_status_data[resource.api_type][resource.api_name],
                              h[:job],
                              job_for_api)
          end
        end

        # We now compute the final status from the api_status_data
        api_status_data.each do |api_type, type_status_data|
          type_status_data.each do |api_resource_name, aggregatated_status_data|
            api_status[api_type] ||= {}
            api_status[api_type][api_resource_name] = derive_api_status(api_type,
                                                                        api_status[api_type][api_resource_name],
                                                                        aggregatated_status_data)
          end
        end

        api_status
      end # def status

      def get_active_jobs_with_resources(options = {})
        active_jobs_by_moldable_id = {}
        jobs = options[:waiting] == 'no' ? Job.expanded.active_not_waiting : Job.expanded.active
        usefull_jobs = nil
        usefull_jobs = jobs.includes(:job_types)
        ActiveSupport::Notifications.instrument('OAR::Resource.get_active_jobs_with_resources do the SQL and create active_jobs_by_moldable_id',
                                                options) do
          usefull_jobs
            .each do |job|
              active_jobs_by_moldable_id[job.moldable_id] = {
                # using job.resources will generate a query by job,
                # and eager loading (the :include => [:job_types, :resources]  will not work
                # for association defined by :finder_sql such a resources
                # initialize resources to an empty set
                resources: Set.new,
                job: job
              }
          end
        end
        # if there are jobs
        if active_jobs_by_moldable_id.length > 0
          moldable_ids = active_jobs_by_moldable_id.keys.join(',')

          # get all resources assigned to these jobs in one query
          query = "(#{QUERY_ASSIGNED_RESOURCES}) UNION (#{QUERY_GANTT_JOBS_RESOURCES})"
          connection.execute(
            query.gsub(
              /%MOLDABLE_IDS%/, moldable_ids
            )
          ).each do |row|
            if row.is_a?(Hash)
              moldable_job_id = row['moldable_job_id'].to_i
              resource_id = row['resource_id'].to_i
            else
              (moldable_job_id, resource_id) = row
              resource_id = resource_id.to_i
              moldable_job_id = moldable_job_id.to_i
            end
            active_jobs_by_moldable_id[moldable_job_id][:resources]
              .add(resource_id)
          end # .each do |(moldable_job_id, resource_id)|
        end # if active_jobs_by_moldable_id
        active_jobs_by_moldable_id
      end

      # Returns the status hash for a resource with no jobs
      def initial_status_for(resource)
        h = { hard: resource.state }
        # Check if resource is in standby state
        if resource.state == 'absent' && resource.available_upto && resource.available_upto == STANDBY_AVAILABLE_UPTO
          h[:hard] = 'standby'
        end

        case resource.type
        when 'default'
          h[:soft] = resource.dead? ? 'unknown' : 'free'
          h[:comment] = resource.comment if resource.respond_to?(:comment)
        when 'disk'
          h[:soft] = 'free'
          h[:diskpath] = resource.diskpath
        when /^(kavlan|kavlan-global|kavlan-local)$/
          h[:soft] = 'free'
          h[:type] = resource.type
        else
          h[:soft] = 'free'
        end
        h
      end

      # Creates accumulator for resources described at API level
      # that are an aggregation of OAR resources
      # so as to be able to compute their aggregated status
      def initial_status_data_for(resource, include_details)
        initial_data =
          if resource.api_type == 'nodes'
            {
              totalcores: 0,
              busycounter: 0,
              besteffortcounter: 0
            }
          else
            {}
          end
        initial_data[:reservations] = Set.new if include_details
        initial_data
      end

      def update_with_resource(current_data, resource)
        current_data[:totalcores] += 1 if resource.api_type == 'nodes'
        current_data
      end

      def update_with_job(api_type, current_data, oar_job, job_for_api)
        if oar_job.running?
          if api_type == 'nodes'
            current_data[:busycounter] += 1
            current_data[:besteffortcounter] += 1 if oar_job.besteffort?
          else
            current_data[:soft] = 'busy'
          end
        end
        current_data[:reservations].add(job_for_api) unless job_for_api.nil?
        current_data
      end

      def derive_api_status(api_type, initial_status, current_data)
        derived_status = initial_status

        %i[reservations soft].each do |key|
          derived_status[key] = current_data[key] if current_data.has_key?(key)
        end

        # do specific calculation for some api_types
        if api_type == 'nodes'
          # At this stage we have the the complete status over all cores in each node (network_address)
          # Now add logic to sum up the status over all cores and push final status to api_status hash table
          if current_data[:busycounter] > 0
            if current_data[:busycounter] <= current_data[:totalcores] / 2
              derived_status[:soft] = 'free_busy' # more free cores in node than busy cores
            elsif current_data[:busycounter] > current_data[:totalcores] / 2 && current_data[:busycounter] < current_data[:totalcores]
              derived_status[:soft] = 'busy_free' # more busy cores in node than free cores
            else
              derived_status[:soft] = 'busy'      # all cores in node are busy
            end
            if current_data[:besteffortcounter] > 0
              derived_status[:soft] += '_besteffort' # add "_besteffort" after status if it is so
            end
          end

          if derived_status[:soft] == 'unknown'
            %i[free_slots freeable_slots busy_slots].each { |slot| derived_status[slot] = 0 }
          else
            derived_status[:free_slots] = current_data[:totalcores] - current_data[:busycounter]
            derived_status[:freeable_slots] = current_data[:besteffortcounter]
            derived_status[:busy_slots] = current_data[:busycounter] - current_data[:besteffortcounter]
          end
        end
        derived_status
      end
    end # class << self
  end # class Resource
end # module OAR
