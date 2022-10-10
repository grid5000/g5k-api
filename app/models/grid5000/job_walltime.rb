# Copyright (c) 2022 Samir Noir, INRIA Grenoble - Rhône-Alpes
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

module Grid5000
  class JobWalltime
    include Swagger::Blocks

    attr_reader :errors

    READ_WRITE_ATTRIBUTES = %i[walltime delay_next_jobs force whole timeout].freeze
    YES_NO_ATTRIBUTES = %i[delay_next_jobs force whole].freeze
    attr_accessor(*READ_WRITE_ATTRIBUTES)

    # Swagger doc
    swagger_component do
      schema :JobWalltimeSubmit do
        key :required, [:walltime]

        property :walltime do
          key :type, :string
          key :description, 'The new wanted walltime, format is <[+]new walltime>. ' \
            'If no signed is used, the value is absolute.'
          key :example, '+01:30'
        end

        property :force do
          key :type, :boolean
          key :description, 'Request walltime increase to be trialed or applied ' \
            'immediately regardless of any otherwise configured delay. Must be ' \
            'authorized in OAR configuration.'
          key :default, false
          key :example, false
        end

        property :delay_next_jobs do
          key :type, :boolean
          key :description, 'Request walltime increase to possibly delay next ' \
            'batch jobs. Must be authorized in OAR configuration.'
          key :default, false
          key :example, false
        end

        property :whole do
          key :type, :boolean
          key :description, 'Request walltime increase to be trialed or applied ' \
            'wholly at once, or not applied otherwise.'
          key :default, false
          key :example, true
        end

        property :timeout do
          key :type, :integer
          key :description, 'Specify a timeout (in seconds) after which the ' \
            'walltime change request will be aborted if not already accepted by ' \
            'the scheduler. A default timeout could be set in OAR configuration.'
          key :example, 3600
        end
      end

      schema :JobWalltime do
        property :uid do
          key :type, :integer
          key :description, "The job id."
          key :example, 2153572
        end

        property :walltime do
          key :type, :string
          key :description, "The job walltime."
          key :example, '+5:0:0'
        end

        property :possible do
          key :type, :string
          key :description, "Possible walltime increase authorized in OAR configuration, " \
            "can be 'UNLIMITED' or a duration with '0:0:0' format."
          key :example, 'UNLIMITED'
        end

        property :timeout do
          key :type, :string
          key :description, "Current walltime change request timeout."
          key :example, '0:0:5'
        end

        property :force do
          key :type, :string
          key :description, "Describe if current walltime change was made with 'force' " \
            "option, 'FORBIDDEN' if disabled for current user."
          key :enum, ['NO', 'YES', 'FORBIDDEN']
          key :example, 'YES'
          key :default, 'NO'
        end

        property :delay_next_jobs do
          key :type, :string
          key :description, "Describe if current walltime change was made with 'delay_next_jobs' " \
            "option, 'FORBIDDEN' if disabled for current user."
          key :enum, ['NO', 'YES', 'FORBIDDEN']
          key :example, 'YES'
          key :default, 'NO'
        end

        property :whole do
          key :type, :string
          key :description, "Describe if current walltime change was made with 'whole' " \
            "option."
          key :enum, ['NO', 'YES']
          key :example, 'YES'
          key :default, 'NO'
        end

        property :granted do
          key :type, :string
          key :description, 'Total granted walltime duration change that was made.'
          key :example, '+0:0:0'
        end

        property :pending do
          key :type, :string
          key :description, 'Pending walltime duration change.'
          key :example, '+0:30:0'
        end

        property :granted_with_whole do
          key :type, :string
          key :description, "Granted walltime duration that was made using 'whole' " \
            "option."
          key :example, '+1:0:0'
        end

        property :granted_with_force do
          key :type, :string
          key :description, "Granted walltime duration that was made using 'force' " \
            "option."
          key :example, '+1:0:0'
        end

        property :granted_with_delay_next_jobs do
          key :type, :string
          key :description, "Granted walltime duration that was made using " \
            "'delay_next_jobs' option."
          key :example, '+0:0:0'
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
            'href':'/%%API_VERSION%%/sites/grenoble/jobs/2153572/walltime',
            'type':'application/vnd.grid5000.item+json'
          },
          {
            'rel':'parent',
            'href':'/%%API_VERSION%%/sites/grenoble/jobs/2153572',
            'type':'application/vnd.grid5000.item+json'
          }]
        end
      end
    end

    def initialize(h = {})
      @errors = []
      h = h.to_h.symbolize_keys
      READ_WRITE_ATTRIBUTES.each do |attribute|
        value = h[attribute]
        value.symbolize_keys! if value.is_a?(Hash)
        instance_variable_set "@#{attribute}", value
      end
    end

    # valid? method is also doing some adjusments about values contained in
    # YES_NO_ATTRIBUTES. This might be better to write a separate method (but
    # will duplicate code).
    def valid?
      @errors = []
      @errors << 'you must give a new walltime' if walltime.blank?
      @errors << 'new walltime must be a String' if !walltime.blank? && !walltime.is_a?(String)
      @errors << 'timeout must be an Integer' if !timeout.blank? && !timeout.is_a?(Integer)

      # We support Booleans for YES_NO_ATTRIBUTES and also Strings with 'yes/no',
      # however only Booleans is documented.
      # OAR's Rest API needs 'yes/no' Strings, we transform the Booleans to
      # 'yes/no' Strings.
      YES_NO_ATTRIBUTES.each do |attribute|
        value = instance_variable_get "@#{attribute}"
        if !value.nil?
          if !([TrueClass, FalseClass].include?(value.class) ||
              (value.is_a?(String) && ['yes', 'no'].include?(value)))
            @errors << "#{YES_NO_ATTRIBUTES.join(', ')} must be a Boolean"
            break
          else
            case value
            when TrueClass
              instance_variable_set "@#{attribute}", 'yes'
            when FalseClass
              instance_variable_set "@#{attribute}", 'no'
            else
            end
          end
        end
      end

      @errors.empty?
    end
  end
end
