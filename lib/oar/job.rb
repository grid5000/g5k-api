module OAR
  class Job < Base
    set_table_name "jobs"
    set_primary_key :job_id

    # There may be a way to do that more cleanly ;-)
    QUERY_RESOURCES = '
      (
        SELECT resources.*
        FROM resources
        INNER JOIN assigned_resources
          ON assigned_resources.resource_id = resources.resource_id
        INNER JOIN moldable_job_descriptions
          ON assigned_resources.moldable_job_id = moldable_job_descriptions.moldable_id
        INNER JOIN gantt_jobs_predictions
          ON gantt_jobs_predictions.moldable_job_id = moldable_job_descriptions.moldable_id
        INNER JOIN jobs
          ON jobs.job_id = moldable_job_descriptions.moldable_job_id
          AND jobs.job_id = \'#{id}\'
      )
      UNION
      (
        SELECT resources.*
        FROM resources
        INNER JOIN gantt_jobs_resources
          ON gantt_jobs_resources.resource_id = resources.resource_id
        INNER JOIN moldable_job_descriptions
          ON gantt_jobs_resources.moldable_job_id = moldable_job_descriptions.moldable_id
        INNER JOIN gantt_jobs_predictions
          ON gantt_jobs_predictions.moldable_job_id = moldable_job_descriptions.moldable_id
        INNER JOIN jobs
          ON jobs.job_id = moldable_job_descriptions.moldable_job_id
          AND jobs.job_id = \'#{id}\'
      )
    '

    has_many :resources, :finder_sql => QUERY_RESOURCES




    attr_accessor :links

    def state
      value = read_attribute(:state)
      value.downcase! unless value.nil?
      value
    end

    def walltime
      value = read_attribute(:walltime)
      value = value.to_i unless value.nil?
      value
    end

    def user; job_user; end
    def name; job_name; end
    def queue; queue_name; end
    def uid; job_id; end

    def besteffort?
      queue && queue == "besteffort"
    end

    def running?
      state && state == "running"
    end


    def assigned_nodes
      resources_by_type['nodes'].uniq
    end

    def resources_by_type
      h = {}
      resources.each do |resource|
        case resource.type
        when 'default'
          h['nodes'] ||= []
          h['nodes'].push(resource.network_address)
        when /vlan/
          h['vlans'] ||= []
          h['vlans'].push(resource.vlan)
        when /subnet/
          h['subnets'] ||= []
          h['subnets'].push([resource.ip, resource.range].join("/"))
        end
      end
      h
    end

    def to_reservation
      h = {}
      [
        :uid,
        :user, :start_time, :predicted_start_time,
        :walltime, :queue,
        :state, :project, :name,
        :links
      ].each do |k|
        value = send(k) rescue nil
        h[k] = value unless value.nil?
      end
      h
    end

    def as_json(options = {})
      h = to_reservation
      options[:methods] && options[:methods].each do |method|
        value = send(method)
        h[method] = value unless value.nil?
      end
      h
    end



    class << self
      def active
        where("state NOT IN ('Terminated', 'Error')")
      end # def active

      def expanded
        Job.select("jobs.*, moldable_job_descriptions.moldable_walltime AS walltime, gantt_jobs_predictions.start_time AS predicted_start_time,  moldable_job_descriptions.moldable_id").
          joins("LEFT OUTER JOIN moldable_job_descriptions ON jobs.job_id = moldable_job_descriptions.moldable_job_id").
          joins("LEFT OUTER JOIN gantt_jobs_predictions ON gantt_jobs_predictions.moldable_job_id = moldable_job_descriptions.moldable_id")
      end # def expanded
    end
  end
end
