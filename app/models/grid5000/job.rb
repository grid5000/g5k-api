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
  
  attr_reader :errors
  
  READ_ONLY_ATTRIBUTES = [:uid, :user_uid, :submitted_at, :started_at,
    :types, :assigned_nodes, :events, :resources, :reservation, :properties,
    :scheduled_at, :walltime, :queue, :state, :mode,
    :command, :directory, :exit_code, :signal, :checkpoint, :anterior,
    :message, :stderr, :stdout]
  # abasu bug ref. 7360 - added :job_key_from_file --- 29.11.2016
  # OAR expects these as import-job-key-from-file
  READ_ONLY_UNDERSCORE_ATTRIBUTES = [:import_job_key_from_file]
  READ_WRITE_ATTRIBUTES = [:name, :project]
  attr_reader *READ_ONLY_ATTRIBUTES
  attr_reader *READ_ONLY_UNDERSCORE_ATTRIBUTES
  attr_accessor *READ_WRITE_ATTRIBUTES
  
  def initialize(h = {})
    @errors = []
    h = h.symbolize_keys
    (READ_ONLY_ATTRIBUTES+READ_WRITE_ATTRIBUTES+READ_ONLY_UNDERSCORE_ATTRIBUTES).each do |attribute|
      if READ_ONLY_UNDERSCORE_ATTRIBUTES.include?(attribute)
        value = h[attribute.to_s.gsub('_','-').to_sym]
      else
        value = h[attribute]
      end
      value.symbolize_keys! if value.kind_of?(Hash)
      instance_variable_set "@#{attribute.to_s}", value
    end
    normalize!
  end
  
  def normalize!
    @state.downcase! unless @state.nil?
    @message = nil if @message && @message.empty?
    if @reservation && @reservation.kind_of?(String)
      @reservation = Time.parse(@reservation) rescue nil
    end
    %w{uid signal exit_code checkpoint anterior submitted_at scheduled_at started_at walltime reservation}.each do |integer_field|
      value = instance_variable_get "@#{integer_field}"
      instance_variable_set "@#{integer_field}", value.to_i unless value.nil?
    end
    @on_launch = {} if @on_launch.nil?
  end
  
  def to_hash(options = {})
    options = options.symbolize_keys
    h = {}
    case options.delete(:destination)
    when "oar-2.4-submission"
      h["resource"] = resources
      h["script"] = command
      h["reservation"] = Time.at(reservation).strftime("%Y-%m-%d %H:%M:%S") unless reservation.nil?
      h["property"] = properties unless properties.nil? || properties.empty?
      h["type"] = types unless types.nil? || types.empty?

      %w{walltime queue directory name project signal checkpoint stderr stdout}.each do |prop|
        value = instance_variable_get "@#{prop}"
        h[prop] = value unless value.nil?
      end
      # abasu bug ref. 7360 - added import_job_key_from_file --- 29.11.2016
      %w{import-job-key-from-file}.each do |prop|
        value = instance_variable_get "@#{prop.gsub('-','_')}"
        h[prop] = value unless value.nil?
      end
      # --hold
      # --stdout=<file> 
      # --stderr=<file>
      # --use-job-key ?
      # --notify ? (if file:// => --notify "exec:/...") ?
      # --anterior : array ?
    else
      (READ_ONLY_ATTRIBUTES+READ_WRITE_ATTRIBUTES).each {|attribute|
        value = instance_variable_get("@#{attribute.to_s}")
        h[attribute.to_s] = value unless value.nil?
      }
      if (link_proc = options[:links]) && link_proc.kind_of?(Proc)
        h["links"] = link_proc.call(self)
      end
    end

    h
  end
  
  def submission?
    reservation.nil?
  end
  
  def valid?
    @errors = []
    if submission? && (command.nil? || command.empty?)
      errors << "you must give a :command to execute on launch"
    end
    @errors.empty?
  end
  
end
end
