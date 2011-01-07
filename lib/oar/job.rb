module OAR
  class Job < Base
    set_table_name "jobs"
    set_primary_key :job_id
    
    QUERY_ACTIVE_JOBS = %{
      SELECT 
        jobs.job_id, jobs.state, jobs.queue_name, jobs.start_time,
        jobs.job_name, jobs.project, jobs.job_user,
        moldable_job_descriptions.moldable_walltime AS walltime,
        moldable_job_descriptions.moldable_id 
      FROM 
        jobs
      INNER JOIN 
        moldable_job_descriptions 
        ON jobs.job_id = moldable_job_descriptions.moldable_job_id 
        AND moldable_job_descriptions.moldable_index = 'CURRENT'
      WHERE jobs.state 
        NOT IN ('Terminated', 'Error')
    }
    
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
    
    
    def assigned_resources
      @assigned_resources ||= Set.new
    end
    
    def to_reservation
      h = {}
      [
        :uid,
        :user, :start_time, :walltime, :queue, 
        :state, :project, :name
      ].each do |k|
        value = send(k)
        h[k] = value unless value.nil?
      end
      h
    end
    
    class << self
      def active
        Job.find_by_sql(QUERY_ACTIVE_JOBS)
      end
    end
  end
end
