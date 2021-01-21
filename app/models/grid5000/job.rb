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

require 'time'

module Grid5000
  # Class representing a Grid5000 job.
  class Job
    include Swagger::Blocks

    attr_reader :errors

    READ_ONLY_ATTRIBUTES = %i[uid user_uid submitted_at started_at
                              types assigned_nodes events resources reservation properties
                              scheduled_at walltime queue state mode
                              command directory exit_code signal checkpoint anterior
                              message stderr stdout].freeze

    # OAR expects these as import-job-key-from-file
    READ_ONLY_UNDERSCORE_ATTRIBUTES = [:import_job_key_from_file].freeze
    READ_WRITE_ATTRIBUTES = %i[name project workdir].freeze
    attr_reader(*READ_ONLY_ATTRIBUTES)
    attr_reader(*READ_ONLY_UNDERSCORE_ATTRIBUTES)
    attr_accessor(*READ_WRITE_ATTRIBUTES)

    # Swagger doc
    swagger_component do
      parameter :jobId do
        key :name, :jobId
        key :in, :path
        key :description, 'ID of job to fetch.'
        key :required, true
        schema do
          key :type, :string
        end
      end

      parameter :jobQueue do
        key :name, :queue
        key :in, :path
        key :description, 'Filter jobs with a specific queue.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :jobProject do
        key :name, :project
        key :in, :query
        key :description, 'Filter jobs with a specific project name.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :jobUser do
        key :name, :user
        key :in, :query
        key :description, 'Filter jobs with a specific owner.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :jobName do
        key :name, :name
        key :in, :query
        key :description, 'Filter jobs with a specific name.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :jobState do
        key :name, :state
        key :in, :query
        key :description, 'Filter jobs by state (waiting, launching, running, '\
          'hold, error, terminated), as a comma-separated list.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :jobResources do
        key :name, :resources
        key :in, :query
        key :description, "Get more details (assigned_nodes and resources_by_types) "\
          "for each job in the list. Should be 'yes' or 'no'."
        key :required, false
        schema do
          key :type, :string
          key :pattern, '^(no|yes)$'
          key :default, 'no'
        end
      end

      schema :OarEvent do
        key :required, [:uid, :created_at, :type, :description]

        property :uid do
          key :type, :integer
          key :description, 'The OAR event unique ID.'
          key :example, 7002358
        end

        property :created_at do
          key :type, :integer
          key :description, 'The timestamp of event creation.'
          key :example, 1605713978
        end

        property :type do
          key :type, :string
          key :description, 'The event type.'
          key :example, 'SEND_KILL_JOB'
        end

        property :description do
          key :type, :string
          key :description, 'A description of the event.'
          key :example, '[Leon] Send the kill signal to oarexec on frontend for job 4242'
        end
      end

      schema :JobCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :'$ref', :JobItems
          end
          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/3.0/sites/grenoble/jobs',
                  'type':'application/vnd.grid5000.item+json'
                },
                {
                  'rel':'parent',
                  'href':'/3.0/sites/grenoble',
                  'type':'application/vnd.grid5000.item+json'
                }]
            end
          end
        end
      end

      schema :JobItems do
        key :required, [:items]
        property :items do
          key :type, :array
          items do
            key :'$ref', :Job
          end
        end
      end

      schema :Job do
        key :required, [:uid, :user_uid, :user, :walltime, :queue, :state,
                        :project, :name, :types, :mode, :command, :submitted_at,
                        :started_at, :stopped_at, :message, :properties,
                        :directory, :events]

        property :uid do
          key :type, :integer
          key :description, 'The unique identifier of the job.'
          key :example, 42
        end

        property :user_uid do
          key :type, :string
          key :description, "The job's owner."
          key :example, 'user'
        end

        property :user_uid do
          key :type, :string
          key :description, "The job's owner."
          key :example, 'user'
        end

        property :walltime do
          key :type, :integer
          key :description, 'The walltime of job, in seconds.'
          key :example, 3600
        end

        property :queue do
          key :type, :string
          key :description, "The job's queue."
          key :example, 'default'
        end

        property :state do
          key :type, :string
          key :description, 'The state of job, can be: waiting, launching, ' \
            'running, hold, error, terminated.'
          key :example, 'running'
        end

        property :project do
          key :type, :string
          key :description, "The job's project."
          key :example, 'running'
        end

        property :name do
          key :type, :string
          key :description, "The job's name."
          key :example, 'My awesome job'
        end

        property :type do
          key :type, :array
          items do
            key :type, :string
          end

          key :description, "The OAR job's types."
          key :example, ['deploy', 'night']
        end

        property :mode do
          key :type, :string
          key :description, "The job's mode ('INTERACTIVE or PASSIVE')."
          key :example, 'PASSIVE'
        end

        property :command do
          key :type, :string
          key :description, "The job's command."
          key :example, './my-script.sh'
        end

        property :submitted_at do
          key :type, :integer
          key :description, "The job's submission time, as a timestamp."
          key :example, 1605712132
        end

        property :started_at do
          key :type, :integer
          key :description, "The job's start time, as a timestamp."
          key :example, 1605712452
        end

        property :stopped_at do
          key :type, :integer
          key :description, "The job's stop time (if already stopped), as a timestamp."
          key :example, 1605713607
        end

        property :message do
          key :type, :string
          key :description, "Various OAR message."
          key :example, 'FIFO scheduling OK'
        end

        property :properties do
          key :type, :string
          key :description, "SQL constraints on OAR's resources."
          key :example, "(cluster='troll') AND maintenance = 'NO'"
        end

        property :directory do
          key :type, :string
          key :description, 'Directory of command launch.'
          key :example, '/home/user/'
        end

        property :events do
          key :type, :array
          key :description, 'List of OAR events for job (like a kill request, and '\
            'then the killed by OAR event.'
          items do
            key :'$ref', :OarEvent
          end
        end

        property :assigned_nodes do
          key :type, :array
          key :description, 'List of nodes assigned to job (if any).'
          items do
            key :type, :string
            key :format, :hostname
          end
          key :example, ['dahu-20.grenoble.grid5000.fr', 'dahu-21.grenoble.grid5000.fr']
        end

        property :resources_by_types do
          key :type, :object
          key :description, "Assigned resources to job, by type ('cores', 'vlans', "\
            "subnets, disks)."

          property :cores do
            key :type, :array
            items do
              key :type, :string
              key :format, :hostname
            end
            key :example, ['dahu-20.grenoble.grid5000.fr/1', 'dahu-21.grenoble.grid5000.fr/1']
          end
          property :vlans do
            key :type, :array
            items do
              key :type, :integer
            end
            key :example, [4]
          end
          property :disks do
            key :type, :array
            items do
              key :type, :string
            end
            key :example, ['sdb.yeti-1.grenoble.grid5000.fr',
                           'sdb.yeti-2.grenoble.grid5000.fr']
          end
          property :subnets do
            key :type, :array
            items do
              key :type, :string
            end
            key :example, ['10.134.92.0/22']
          end
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
             'href':'/3.0/sites/grenoble/jobs/42',
             'type':'application/vnd.grid5000.item+json'
            },
            {
              'rel':'parent',
              'href':'/3.0/sites/grenoble',
              'type':'application/vnd.grid5000.item+json'
            }]
        end
      end

      schema :JobSubmit do
        key :required, [:command]

        property :resources do
          key :type, :string
          key :description, 'A description of the resources you want to book for '\
            'your job, in OAR format.'
          key :example, 'nodes=3,walltime=02:00'
          key :default, 'nodes=1'
        end

        property :directory do
          key :type, :string
          key :description, 'The directory in which the command will be launched.'
          key :default, '/home/{user}'
          key :example, '~/my-job'
        end

        property :command do
          key :type, :string
          key :description, 'The command to execute when the job starts.'
          key :example, './my-script.sh'
        end

        property :stderr do
          key :type, :string
          key :description, 'The path to the file that will contain the STDERR '\
            'output of your command.'
          key :default, '{directory}/OAR.%jobid%.stderr'
          key :example, '{directory}/OAR.%jobid%.stderr'
        end

        property :stdout do
          key :type, :string
          key :description, 'The path to the file that will contain the STDOUT '\
            'output of your command.'
          key :default, '{directory}/OAR.%jobid%.stdout'
          key :example, '{directory}/OAR.%jobid%.stdout'
        end

        property :properties do
          key :type, :string
          key :description, 'A string containing SQL constraints on the resources '\
            '(see OAR documentation for more details).'
          key :example, "(cluster='troll')"
        end

        property :reservation do
          key :type, :string
          key :description, 'If you want your job to be scheduled at a specific '\
            'date, as a UNIX timestamp, OR a string containing a date in a '\
            'reasonable format.'
          key :example, '2020-19-12 14:35:00 GMT+0100'
        end

        property :types do
          key :type, :array
          key :description, 'An array of job types.'
          items do
            key :type, :string
          end

          key :example, ['deploy', 'night']
        end

        property :project do
          key :type, :string
          key :description, 'A project name to link your job to, set by default '\
            'to the default one specified (if so) in UMS (known as GGA).'
          key :example, 'my-lab-project'
        end

        property :name do
          key :type, :string
          key :description, 'A job name.'
          key :example, 'My awesome job'
        end

        property :queue do
          key :type, :string
          key :description, 'A job queue.'
          key :default, 'default'
          key :example, 'production'
        end
      end
    end

    def initialize(h = {})
      @errors = []
      h = h.to_h.symbolize_keys
      (READ_ONLY_ATTRIBUTES + READ_WRITE_ATTRIBUTES + READ_ONLY_UNDERSCORE_ATTRIBUTES).each do |attribute|
        value = if READ_ONLY_UNDERSCORE_ATTRIBUTES.include?(attribute)
                  h[attribute.to_s.gsub('_', '-').to_sym]
                else
                  h[attribute]
                end
        value.symbolize_keys! if value.is_a?(Hash)
        instance_variable_set "@#{attribute}", value
      end
      normalize!
    end

    def normalize!
      @state&.downcase!
      @message = nil if @message&.empty?
      if @reservation.is_a?(String)
        @reservation = begin
                         Time.parse(@reservation)
                       rescue StandardError
                         nil
                       end
      end
      %w[uid signal exit_code checkpoint anterior submitted_at scheduled_at started_at walltime reservation].each do |integer_field|
        value = instance_variable_get "@#{integer_field}"
        instance_variable_set "@#{integer_field}", value.to_i unless value.nil?
      end
      @workdir = @directory
      @on_launch = {} if @on_launch.nil?
    end

    def to_hash(options = {})
      options = options.symbolize_keys
      h = {}
      case options.delete(:destination)
      when 'oar-2.4-submission'
        h['resource'] = resources
        h['script'] = command
        h['reservation'] = Time.at(reservation).strftime('%Y-%m-%d %H:%M:%S') unless reservation.nil?
        h['property'] = properties unless properties.nil? || properties.empty?
        h['type'] = types unless types.nil? || types.empty?

        %w[walltime queue directory name project signal checkpoint stderr stdout workdir].each do |prop|
          value = instance_variable_get "@#{prop}"
          h[prop] = value unless value.nil?
        end

        %w[import-job-key-from-file].each do |prop|
          value = instance_variable_get "@#{prop.gsub('-', '_')}"
          h[prop] = value unless value.nil?
        end
      else
        (READ_ONLY_ATTRIBUTES + READ_WRITE_ATTRIBUTES).each do |attribute|
          value = instance_variable_get("@#{attribute}")
          h[attribute.to_s] = value unless value.nil?
        end
        if (link_proc = options[:links]) && link_proc.is_a?(Proc)
          h['links'] = link_proc.call(self)
        end
      end

      h
    end

    def submission?
      reservation.nil?
    end

    def valid?
      @errors = []
      errors << 'you must give a :command to execute on launch' if submission? && command.blank?
      @errors.empty?
    end
  end
end
