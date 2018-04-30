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
        job_details = options[:job_details] != 'no'
        include_comment = columns.find{|c| c.name == "comment"}

 	# abasu for bug 5106 : added cluster & core in MySQL request - 05.02.2015
        resources = Resource.select(
          "resource_id, cluster, network_address, core, state, available_upto#{include_comment ? ", comment" : ""}"
        )

        resources = resources.where(
          :network_address => options[:network_address]
        ) unless options[:network_address].blank?

        resources = resources.where(
          :cluster => options[:clusters]
        ) unless options[:clusters].blank?

        # Remove blank network addresses
        resources = resources.where("network_address <> ''")

        resources = resources.index_by(&:resource_id)
        
 	# abasu : Introduce a hash table to store counts of free / busy cores per node - 05.02.2015
        # abasu : This hash table can be used to store other counters in future (add another element)
        nodes_counter = {}
	resources.each do |resource_id, resource|
          next if resource.nil?

	  nodes_counter[resource.network_address]= {
                :totalcores => 0,
                :busycounter => 0,
                :besteffortcounter => 0
              } if !nodes_counter.has_key?(resource.network_address)
          if !resource.core.zero?
            # core=0 for non default type of resources
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
            # The resource does not belong to a valid cluster.
            next if resource.nil?

            result[resource.network_address] ||= initial_status_for(resource, job_details)

	    # abasu : if job is current, increment corresponding counter(s) in hash table
            if current
              nodes_counter[resource.network_address][:busycounter] += 1
              if h[:job].besteffort?
                nodes_counter[resource.network_address][:besteffortcounter] += 1
              end #  if h[:job].besteffort?
            end  # if current

            result[resource.network_address][:reservations].add(jobh) if job_details
          end  # .each do |resource_id|
        end  # .each do |moldable_id, h|

        # abasu : At this stage we have the the complete status over all cores in each node (network_address)
        # abasu : Now add logic to sum up the status over all cores and push final status to result hash table

 
        nodes_counter.each do |network_address, node_counter|
          next if result[network_address].nil?
          next if result[network_address][:hard] == 'dead'

          if node_counter[:busycounter] == 0
            result[network_address][:soft] = "free"      # all cores in node are free
          end
          if node_counter[:busycounter] > 0 && node_counter[:busycounter] <= node_counter[:totalcores] / 2
	    result[network_address][:soft] = "free_busy" # more free cores in node than busy cores
          end
          if node_counter[:busycounter] > node_counter[:totalcores] / 2 && node_counter[:busycounter] < node_counter[:totalcores]
	    result[network_address][:soft] = "busy_free" # more busy cores in node than free cores
          end
          if node_counter[:busycounter] == node_counter[:totalcores] 
	    result[network_address][:soft] = "busy"      # all cores in node are busy
	  end  # nested if

          if node_counter[:besteffortcounter] > 0
	    result[network_address][:soft] += "_besteffort" # add "_besteffort" after status if it is so
          end # if node_counter[:besteffortcounter]
        end  # .each do |network_address, node_counter|

        # fallback for resources without jobs
        resources.each do |resource_id, resource|
          result[resource.network_address] ||= initial_status_for(resource, job_details)
        end  # .each do |resource_id, resource|

        result
      end # def status

      def get_active_jobs_by_moldable_id(options = {})
        active_jobs_by_moldable_id = {}
        jobs = options[:waiting] == 'no' ? Job.expanded.active_not_waiting : Job.expanded.active
        jobs.
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

      # Returns the initial status hash for a resource.
      def initial_status_for(resource, job_details)
        hard = resource.state
        # Check if resource is in standby state
        if hard == 'absent' && resource.available_upto && resource.available_upto == STANDBY_AVAILABLE_UPTO
          hard = 'standby'
        end
        h = {
          :hard => hard,
          :soft => resource.dead? ? "unknown" : "free",
        }
        h[:reservations] = Set.new if job_details
        h[:comment] = resource.comment if resource.respond_to?(:comment)
        h
      end  # def initial_status_for

      # Returns the status of all disks, indexed by the disk location.
      # So, it returns only one entry per disk.
      #
      # Returns a hash of the following format:
      #
      #   {
      #     'disk.host' => {
      #       :soft => "free|busy",
      #       :disk => disk identifier,
      #       :diskpath => disk path,
      #       :reservations => [...]
      #     },
      #     {...}
      #   }
      #
      def disk_status(options = {})
        result = {}
        job_details = options[:job_details] != 'no'

        resources = Resource.select(
          "resource_id, cluster, host, disk, diskpath"
        )

        # Column host of a disk resource is equal to column
        # network_address of the node it belongs to
        resources = resources.where(
          :host => options[:network_address]
        ) unless options[:network_address].blank?

        resources = resources.where(
          :cluster => options[:clusters]
        ) unless options[:clusters].blank?

        # Keep only disks
        resources = resources.where(
          :type => 'disk'
        )

        resources = resources.index_by(&:resource_id)

        get_active_jobs_by_moldable_id(options).each do |moldable_id, h|
          current = h[:job].running?

          # prepare job description now, since it will be added to each resource
          # For Result hash table, do not include events
          # (otherwise the Set does not work with nested hash)
          jobh = h[:job].to_reservation(:without => :events) if job_details

          h[:resources].each do |resource_id|
            resource = resources[resource_id]

            # The resource is not a disk or does not belong to a valid cluster.
            next if resource.nil?

            disk_key = disk_key(resource.disk, resource.host)
            result[disk_key] ||= initial_disk_status_for(resource, job_details)

            if current
              result[disk_key][:soft] = 'busy'
            else
              result[disk_key][:soft] = 'free'
            end  # if current

            result[disk_key][:reservations].add(jobh) if job_details
          end  # .each do |resource_id|
        end  # .each do |moldable_id, h|

        # fallback for resources without jobs
        resources.each do |resource_id, resource|
          result[disk_key(resource.disk, resource.host)] ||= initial_disk_status_for(resource, job_details)
        end  # .each do |resource_id, resource|

        result
      end # def disk_status

      def disk_key(disk, host)
        [disk.split('.').first, host].join('.')
      end

      # Returns the initial status hash for a disk.
      def initial_disk_status_for(resource, job_details)
        h = {
          :soft => "free",
          :diskpath => resource.diskpath,
        }
        h[:reservations] = Set.new if job_details
        h
      end  # def initial_disk_status
    end # class << self

  end  # class Resource

end  # module OAR
