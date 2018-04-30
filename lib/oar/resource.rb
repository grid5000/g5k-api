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

    QUERY_ASSIGNED_RESOURCES = "SELECT moldable_job_id, resource_id FROM assigned_resources WHERE moldable_job_id IN (%MOLDABLE_IDS%)"
    QUERY_GANTT_JOBS_RESOURCES = "SELECT moldable_job_id, resource_id FROM gantt_jobs_resources WHERE moldable_job_id IN (%MOLDABLE_IDS%)"
    def dead?
      state && state == "dead"
    end

    def state
      value = read_attribute(:state)
      value.downcase! unless value.nil?
      value
    end

    class << self
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
      #
      def status(options = {})
        result = {}
        options[:types]=["node"] if options[:types].nil?
        options[:types].each do |t| result[type_key(t)]={} end
        job_details = options[:job_details] != 'no'
        include_comment = columns.find{|c| c.name == "comment"}

        # abasu for bug 5106 : added cluster & core in MySQL request - 05.02.2015
        resources = Resource.select(
          "resource_id, type, cluster, host, network_address, disk, diskpath, core, state, available_upto#{include_comment ? ", comment" : ""}"
        )

        resources = resources.where(
          '"network_address" = ? OR "host" = ?',options[:network_address],options[:network_address]
        ) unless options[:network_address].blank?

        resources = resources.where(
          :cluster => options[:clusters]
        ) unless options[:clusters].blank?

        # only look for requested types
        # handle node as an alias for default
        had_node=options[:types].delete("node")=="node"
        options[:types].push("default") if had_node
        resources = resources.where(:type => options[:types])

        resources = resources.index_by(&:resource_id)
        
        # abasu : Introduce a hash table to store counts of free / busy cores per node - 05.02.2015
        # abasu : This hash table can be used to store other counters in future (add another element)
        nodes_counter = {}
        resources.each do |resource_id, resource|
          next if resource.nil?

          result[type_key(resource.type)][get_status_key(resource)] ||= initial_status_for(resource, job_details)

          if resource.type=='default'
	          nodes_counter[resource.network_address]= {
              :totalcores => 0,
              :busycounter => 0,
              :besteffortcounter => 0
            } if !nodes_counter.has_key?(resource.network_address)
	          nodes_counter[resource.network_address][:totalcores] += 1
          end
	      end  #  .each do |resource_id, resource|

        get_active_jobs_by_moldable_id(options).each do |moldable_id, h|
          current = h[:job].running?

          # prepare job description now, since it will be added to each resource
          # For Result hash table, do not include events
          # (otherwise the Set does not work with nested hash)
          jobh = h[:job].to_reservation(:without => :events) if job_details

          h[:resources].each do |resource_id|
            resource = resources[resource_id]
            # The resource does not belong to a cluster the caller is interested in.
            next if resource.nil?

	          # abasu : if job is current, increment corresponding counter(s) in hash table
            if current
              if resource.type=='default'
                nodes_counter[resource.network_address][:busycounter] += 1
                if h[:job].besteffort?
                  nodes_counter[resource.network_address][:besteffortcounter] += 1
                end #  if h[:job].besteffort?
              else
                result[type_key(resource.type)][get_status_key(resource)][:soft] = 'busy'
              end
            end  # if current

            result[type_key(resource.type)][get_status_key(resource)][:reservations].add(jobh) if job_details
          end  # .each do |resource_id|
        end  # .each do |moldable_id, h|

        # abasu : At this stage we have the the complete status over all cores in each node (network_address)
        # abasu : Now add logic to sum up the status over all cores and push final status to result hash table
        nodes_counter.each do |network_address, node_counter|
          next if result["nodes"][network_address].nil?
          next if result["nodes"][network_address][:hard] == 'dead'

          if node_counter[:busycounter] == 0
            result["nodes"][network_address][:soft] = "free"      # all cores in node are free
          end
          if node_counter[:busycounter] > 0 && node_counter[:busycounter] <= node_counter[:totalcores] / 2
	          result["nodes"][network_address][:soft] = "free_busy" # more free cores in node than busy cores
          end
          if node_counter[:busycounter] > node_counter[:totalcores] / 2 && node_counter[:busycounter] < node_counter[:totalcores]
	          result["nodes"][network_address][:soft] = "busy_free" # more busy cores in node than free cores
          end
          if node_counter[:busycounter] == node_counter[:totalcores] 
	          result["nodes"][network_address][:soft] = "busy"      # all cores in node are busy
	        end  # nested if

          if node_counter[:besteffortcounter] > 0
	          result["nodes"][network_address][:soft] += "_besteffort" # add "_besteffort" after status if it is so
          end # if node_counter[:besteffortcounter]
        end  # .each do |network_address, node_counter|

        result
      end # def status

      def get_active_jobs_by_moldable_id(options = {})
        active_jobs_by_moldable_id = {}
        jobs = options[:waiting] == 'no' ? Job.expanded.active_not_waiting : Job.expanded.active
        jobs.find(:all, :include => [:job_types]).
          each{|job|
          active_jobs_by_moldable_id[job.moldable_id] = {
            # using job.resources will generate a query by job,
            # and eager loading (the :include => [:job_types, :resources]  will not work
            # for association defined by :finder_sql such a resources
            # initialize resources to an empty set
            :resources => Set.new,
            :job => job
          }
        }

        # if there are jobs
        if active_jobs_by_moldable_id.length > 0
          moldable_ids = active_jobs_by_moldable_id.keys.
            map{|moldable_id| "'#{moldable_id}'"}.join(",")


          # get all resources assigned to these jobs in one query
          query= "(#{QUERY_ASSIGNED_RESOURCES}) UNION (#{QUERY_GANTT_JOBS_RESOURCES})"
          self.connection.execute(
            query.gsub(
              /%MOLDABLE_IDS%/, moldable_ids
            )
          ).each do |row|
            if row.is_a?(Hash)
              moldable_job_id=row["moldable_job_id"]
              resource_id=row["resource_id"].to_i
            else
              (moldable_job_id,resource_id)=row
              resource_id=resource_id.to_i
            end

            active_jobs_by_moldable_id[moldable_job_id][:resources].
              add(resource_id)
          end # .each do |(moldable_job_id, resource_id)|
        end # if active_jobs_by_moldable_id
        active_jobs_by_moldable_id
      end

      def type_key(type)
        if type=="default"
          "nodes"
        else
          type.pluralize
        end
      end

      def get_status_key(resource)
        case resource.type
        when 'default'
          resource.network_address
        when 'disk'
          [resource.disk.split('.').first, resource.host].join('.')
        else
          resource.id
        end
      end

      # Returns the initial status hash for a resource.
      def initial_status_for(resource, job_details)
        hard = resource.state
        # Check if resource is in standby state
        if hard == 'absent' && resource.available_upto && resource.available_upto == STANDBY_AVAILABLE_UPTO
          hard = 'standby'
        end
        h = {:hard => hard}
        case resource.type
        when 'default'
          h[:soft]= resource.dead? ? "unknown" : "free"
          h[:comment] = resource.comment if resource.respond_to?(:comment)
          h
        when 'disk'
          h = {
            :soft => "free",
            :diskpath => resource.diskpath,
          }
        end
        h[:reservations] = Set.new if job_details
        h
      end  # def initial_status_for

    end # class << self

  end  # class Resource

end  # module OAR
