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
  class Job < Base
    self.table_name = 'jobs'
    self.primary_key = :job_id

    has_many :job_types
    has_many :job_events, -> { order 'date ASC' }
    belongs_to :gantt, foreign_key: 'assigned_moldable_job', class_name: 'Gantt'

    attr_accessor :links

    def self.list(params = {})
      jobs = expanded.order('job_id DESC')
      jobs = jobs.where(job_user: params[:user]) unless params[:user].blank?
      jobs = jobs.where(job_name: params[:name]) unless params[:name].blank?
      jobs = jobs.where(project: params[:project]) unless params[:project].blank?
      jobs = jobs.where(job_id: params[:job_id]) unless params[:job_id].blank?
      if params[:state]
        states = (params[:state] || '').split(/\s*,\s*/)
                                       .map(&:capitalize)
                                       .uniq
        jobs = jobs.where(state: states)
      end
      jobs = jobs.where(queue_name: params[:queue]) if params[:queue]
      jobs
    end

    def resources
      query = "
      (
        SELECT resources.*
        FROM resources
        INNER JOIN jobs
          ON jobs.job_id = \'#{id}\'
        INNER JOIN assigned_resources
          ON assigned_resources.resource_id = resources.resource_id
        INNER JOIN moldable_job_descriptions
          ON assigned_resources.moldable_job_id = moldable_job_descriptions.moldable_id
          AND jobs.job_id = moldable_job_descriptions.moldable_job_id
        ORDER BY resources.network_address ASC
      )
      UNION
      (
        SELECT resources.*
        FROM resources
        INNER JOIN jobs
          ON jobs.job_id = \'#{id}\'
        INNER JOIN gantt_jobs_resources
          ON gantt_jobs_resources.resource_id = resources.resource_id
        INNER JOIN moldable_job_descriptions
          ON gantt_jobs_resources.moldable_job_id = moldable_job_descriptions.moldable_id
          AND jobs.job_id = moldable_job_descriptions.moldable_job_id
        ORDER BY resources.network_address ASC
      )"
      Resource.find_by_sql(query)
    end

    def state
      value = read_attribute(:state)
      value&.downcase!
      value
    end

    def walltime
      value = read_attribute(:walltime)
      value = value.to_i unless value.nil?
      value
    end

    def user
      job_user
    end

    def user_uid
      user
    end

    def name
      job_name
    end

    def queue
      queue_name
    end

    def uid
      job_id
    end

    def mode
      job_type
    end

    def submitted_at
      submission_time
    end

    def started_at
      start_time
    end

    def stopped_at
      stop_time && stop_time == 0 ? nil : stop_time
    end

    def directory
      launching_directory
    end

    def events
      job_events
    end

    def scheduled_at
      time = predicted_start_time ? predicted_start_time.to_i : nil
      time = nil if time == 0
      time
    end

    def types
      job_types.map(&:name)
    end

    def besteffort?
      queue && queue == 'besteffort'
    end

    def running?
      state && state == 'running'
    end

    def assigned_nodes
      if resources_by_type['cores']
        resources_by_type['cores'].map { |n| n.gsub(/\/([0-9]+)$/, '') }.uniq
      else
        []
      end
    end

    def resources_by_type
      h = {}
      resources.each do |resource|
        case resource.type
        when 'default'
          h['cores'] ||= []
          h['cores'].push(resource.network_address + '/' + resource.cpuset)
        when /vlan/
          h['vlans'] ||= []
          h['vlans'].push(resource.vlan)
        when /subnet/
          h['subnets'] ||= []
          h['subnets'].push([
            resource.subnet_address,
            resource.subnet_prefix
          ].join('/'))
        when 'disk'
          h['disks'] ||= []
          h['disks'].push([
            resource.disk.split('.').first,
            resource.host
          ].join('.'))
        end
      end

      # Sort by node name and cpuset, to have nodes from a same cluster grouped
      # and listed in correct order. Also sort cpuset number for a node.
      if h['cores']
        h['cores'].sort_by! do |n|
          [n.gsub(/^([A-z]+)\-.*$/, '\1'),
           n.gsub(/^([A-z]+)\-([0-9]+).*/, '\2').to_i,
           n.gsub(/^.*\/([0-9]+)$/, '\1').to_i]
        end
      end

      ['vlans', 'disks', 'subnets'].each do |type|
        h[type].sort if h[type]
      end

      h
    end

    def to_reservation(options = {})
      without = [options[:without] || []].flatten
      h = {}
      [
        :uid,
        :user_uid, # deprecated. to remove.
        :user,
        :walltime,
        :queue,
        :state,
        :project,
        :name,
        :types,
        :mode,
        :command,
        :submitted_at,
        :scheduled_at,
        :started_at,
        :stopped_at,
        :message,
        :exit_code,
        :properties,
        :directory,
        :events,
        :links
      ].each do |k|
        next if without.include?(k)

        value = begin
                  send(k)
                rescue StandardError
                  nil
                end
        h[k] = value unless value.nil?
      end

      h
    end

    def as_json(options = {})
      h = to_reservation
      ((options && options[:methods]) || []).each do |method|
        value = send(method)
        h[method] = value unless value.nil?
      end
      h
    end

    class << self
      def active
        where("state IN ('Waiting','Hold','toLaunch','toError','toAckReservation','Launching','Running','Suspended','Resuming','Finishing')")
      end

      def active_not_waiting
        where("state IN ('Hold','toLaunch','toError','toAckReservation','Launching','Running','Suspended','Resuming','Finishing')")
      end

      def expanded
        Job.select('jobs.*, moldable_job_descriptions.moldable_walltime AS walltime, gantt_jobs_predictions.start_time AS predicted_start_time,  moldable_job_descriptions.moldable_id')
           .joins('LEFT OUTER JOIN moldable_job_descriptions ON jobs.job_id = moldable_job_descriptions.moldable_job_id')
           .joins('LEFT OUTER JOIN gantt_jobs_predictions ON gantt_jobs_predictions.moldable_job_id = moldable_job_descriptions.moldable_id')
      end
    end
  end
end
