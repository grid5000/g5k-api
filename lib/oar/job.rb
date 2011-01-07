module OAR
  class Job < Base
    set_table_name "jobs"
    set_primary_key :job_id
    
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
    
    
    def assigned_resources
      @assigned_resources ||= Set.new
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
    
    def as_json(*args)
      to_reservation
    end
    

    
    class << self
      def active
        expanded.where("state NOT IN ('Terminated', 'Error')")
      end
      def expanded
        Job.select("jobs.*, moldable_job_descriptions.moldable_walltime AS walltime, gantt_jobs_predictions.start_time AS predicted_start_time,  moldable_job_descriptions.moldable_id").
          joins("LEFT OUTER JOIN moldable_job_descriptions ON jobs.job_id = moldable_job_descriptions.moldable_job_id").
          joins("LEFT OUTER JOIN gantt_jobs_predictions ON gantt_jobs_predictions.moldable_job_id = moldable_job_descriptions.moldable_id")
      end
    end
  end
end
