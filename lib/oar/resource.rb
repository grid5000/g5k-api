module OAR
  class Resource < Base
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
      # Returns the status of all resources
      def status(options = {})
        result = {
          # resource-network-address => {
          #   :soft => "free|busy|besteffort|unknown",
          #   :hard => "dead|alive|absent|suspected",
          #   :reservations => [...]
          # }
        }
        resources = Resource.select("resource_id, network_address, state")
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

        active_jobs_by_moldable_id.each do |moldable_id, h|
          
          current = h[:job].running?

          h[:resources].each do |resource_id|
            resource = resources[resource_id]
            # The resource does not belong to a valid cluster.
            next if resource.nil?
            result[resource.network_address] ||= {
              :hard => resource.state,
              :soft => resource.dead? ? "unknown" : "free",
              :reservations => Set.new
            }
            if current
              result[resource.network_address][:soft] = if h[:job].besteffort?
                "besteffort"
              else
                "busy"
              end
            end
            # do not include events 
            # (otherwise the Set does not work with nested hash)
            result[resource.network_address][:reservations].add(
              h[:job].to_reservation(:without => :events)
            )
          end
        end

        resources.each do |resource_id, resource|
          result[resource.network_address] ||= {
            :hard => resource.state,
            :soft => resource.dead? ? "unknown" : "free",
            :reservations => Set.new
          }
        end

        result
      end # def status
    end # class << self

  end



end
