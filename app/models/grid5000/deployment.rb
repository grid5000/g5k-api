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

require 'json'
require 'fileutils'

module Grid5000
  # The Deployment class represents a deployment that is launched using the Kadeploy3 tool.
  class Deployment < ActiveRecord::Base
    attr_accessor :links
    # Ugly hack to make the communication between the controller and the model possible
    attr_accessor :base_uri, :user, :tls_options

    SERIALIZED_ATTRIBUTES = [:nodes, :notifications, :result]

    validates_presence_of :user_uid, :site_uid, :environment, :nodes
    validates_uniqueness_of :uid

    before_save :json_serialize
    after_save :json_deserialize
    after_find :json_deserialize

    before_create do
      self.created_at ||= Time.now.to_i
    end

    before_save do
      self.updated_at = Time.now.to_i
      errors.add(:uid, "must be set") if uid.nil?
      errors.empty?
    end

    def to_param
      uid
    end

    # Experiment states
    state_machine :status, :initial => :waiting do
      after_transition :processing => :canceled, :do => :deliver_notification
      after_transition :processing => :error, :do => :deliver_notification
      after_transition :processing => :terminated, :do => :deliver_notification

      before_transition :processing => :canceled, :do => :cancel_workflow!
      before_transition :waiting => :processing, :do => :launch_workflow!

      event :launch do
        transition :waiting => :processing
      end
      event :process do
        transition :processing => :processing
      end
      event :cancel do
        transition :processing => :canceled
      end
      event :terminate do
        transition :processing => :terminated
      end
      event :fail do
        transition :processing => :error
      end
    end

    def active?
      status?(:processing)
    end

    validate do
      errors.add :nodes, "must be a non-empty list of node FQDN" unless (nodes.kind_of?(Array) && nodes.length > 0)
      errors.add :notifications, "must be a list of notification URIs" unless (notifications.nil? || notifications.kind_of?(Array))
    end

    def processing?
      status.nil? || status == "processing"
    end

    def deliver_notification
      unless notifications.blank?
        begin
          Grid5000::Notification.new(
            notification_message,
            :to => notifications
          ).deliver!
        rescue Exception => e
          Rails.logger.warn "Unable to deliver notification to #{notifications.inspect} for deployment ##{uid}: #{e.class.name} - #{e.message} - #{e.backtrace.join("; ")}"
        end
      end
      true
    end

    # When some attributes such as :key are passed as text strings,
    # we must transform such strings into files
    # and replace the attribute value by the HTTP URI
    # where the original content can be accessed.
    # This is required since Kadeploy3 does not allow to directly
    # pass the content string for such attributes.
    def transform_blobs_into_files!(storage_path, base_uri)
      tmpfiles_dir = File.expand_path(storage_path)
      [:key].each do |attribute|
        value = send(attribute)
        next if value.nil?
        scheme = URI.parse(value).scheme rescue nil
        if scheme.nil?
          filename = [
            user_uid, attribute, Digest::SHA1.hexdigest(value)
          ].join("-")
          # ensure the directory exists...
          FileUtils.mkdir_p(tmpfiles_dir)
          # and write the file to that location
          File.open("#{tmpfiles_dir}/#{filename}", "w") { |f| f.write(value) }
          uri = "#{base_uri}/#{filename}"
          send("#{attribute}=".to_sym, uri)
        end
      end
    end # def transform_blobs_into_files!

    def cancel_workflow!
      raise "cancel_workflow!" if !user or !base_uri # Ugly hack

      connect_options={:timeout => 15,:tls => tls_options}
      http = EM::HttpRequest.new(File.join(base_uri,uid), connect_options).delete(
        :head => {
          #'Accept' => '*/*',
          'X-Remote-Ident' => user,
        }
      )
      http.errback{ error("Unable to contact #{File.join(base_uri,uid)}"); raise self.output+"\n" }

      # Not checked since it avoid touch! to cancel the deployment
      #unless %w{200 201 202 204}.include?(http.response_header.status.to_s)
      #  fail
      #  raise "The deployment no longer exists on the Kadeploy server"
      #end

      true
    end

    def launch_workflow!
      raise "launch_workflow!" if !user or !base_uri # Ugly hack

      params = to_hash
      # The environment was specified as an URL to a description file
      if params['environment'].empty?
        scheme = URI.parse(environment).scheme
        case scheme
        when 'http','https'
          begin
            connect_options={:timeout => 10,:tls => tls_options}
            http = EM::HttpRequest.new(environment, connect_options).get()
            params['environment'] = YAML.load(http.response)
            params['environment']['kind'] = 'anonymous'
          rescue Exception => e
            raise "Error fetching the image description file: #{e.class.name}, #{e.message}"
          end
        else
          raise "Error fetching the image description file: #{scheme} protocol not supported yet"
        end
      else
        params['environment']['kind'] = 'database'
      end
      Rails.logger.info "Submitting: #{params.inspect}"

      connect_options={:timeout => 20,:tls => tls_options}
      http = EM::HttpRequest.new(base_uri, connect_options).post(
        :body => params.to_json,
        :head => {
          'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
          'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
          'X-Remote-Ident' => user,
        }
      )
      http.errback{ error("Unable to contact #{base_uri}"); raise self.output+"\n" }

      if %w{200 201 202 204}.include?(http.response_header.status.to_s)
        update_attribute(:uid, JSON.parse(http.response)['wid'])
      else
        error(get_kaerror(http.response,http.response_header))
        # Cannot continue since :uid is not set
        raise self.output+"\n"
      end

      true
    end

    def touch!
      connect_options={:timeout => 10,:tls => tls_options}
      http = EM::HttpRequest.new(File.join(base_uri,uid), connect_options).get(
        :head => {
          'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
          'X-Remote-Ident' => user,
        }
      )
      http.errback{ error("Unable to contact #{File.join(base_uri,uid)}"); raise self.output+"\n" }

      if %w{200 201 202 204}.include?(http.response_header.status.to_s)
        item = JSON.parse(http.response)

        unless item['error']
          connect_options={:timeout => 15,:tls => tls_options}
          http = EM::HttpRequest.new(File.join(base_uri,uid,'state'), connect_options).get(
            :head => {
              'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
              'X-Remote-Ident' => user,
            }
          )
          http.errback{ error("Unable to contact #{File.join(base_uri,uid,'state')}"); raise self.output+"\n" }
          res = JSON.parse(http.response)
          # Ugly compatibility hack
          res.each_pair do |node,stat|
            res[node]['state'] = res[node]['state'].upcase
          end
          self.result = res
        else
          connect_options={:timeout => 15,:tls => tls_options}
          http = EM::HttpRequest.new(File.join(base_uri,uid,'error'), connect_options).get(
            :head => {
              #'Accept' => '*/*',
              'X-Remote-Ident' => user,
            }
          )
          error(get_kaerror(http.response,http.response_header))
          http.errback{ error("Unable to contact #{File.join(base_uri,uid,'error')}"); raise self.output+"\n" }
          return
        end

        if item['done']
          terminate
        else
          process
        end
      else
        error("The deployment no longer exists on the Kadeploy server")
      end
    end

    def get_kaerror(resp,hdr)
      if hdr['X_APPLICATION_ERROR_CODE'] and hdr['X_APPLICATION_ERROR_INFO']
        "Kadeploy error ##{hdr['X_APPLICATION_ERROR_CODE']}: #{Base64.strict_decode64(hdr['X_APPLICATION_ERROR_INFO'])}"
      else
        "HTTP error ##{hdr.status}: #{resp}"
      end
    end

    def error(msg)
      self.output = msg

      # Delete the workflow from the kadeploy server
      cancel_workflow! if uid

      fail
    end

    def as_json(*args)
      attributes.merge(:links => links).reject{|k,v| v.nil? || k=="id"}
    end

    def notification_message
      ::JSON.pretty_generate(as_json)
    end

    def json_serialize
      SERIALIZED_ATTRIBUTES.each do |att|
        value = send(att)
        if value == [] or ! value.blank?
          send("#{att}=".to_sym, value.to_json)
        end
      end
    end

    def json_deserialize
      SERIALIZED_ATTRIBUTES.each do |att|
        value = send(att) rescue nil
        send("#{att}=".to_sym, (JSON.parse(value) rescue value)) unless value.blank?
      end
    end

    def to_hash
      params = {
        'environment' => {}
      }
      if URI.parse(environment).scheme.nil?
        env_name, env_user = environment.split("@")
        params['environment'] = { 'name' => env_name }
        params['environment']['user'] = env_user if env_user
        params['environment']['version'] = version.to_s if version
      end
      params['ssh_authorized_keys'] = key if key
      params['nodes'] = nodes.dup
      params['deploy_part'] = partition_number.to_s if partition_number
      params['block_device'] = block_device.to_s if block_device
      params['reformat_tmp_partition'] = reformat_tmp.to_s if reformat_tmp
      params['vlan'] = vlan.to_s if vlan
      params['disable_disk_partitioning'] = true if disable_disk_partitioning
      params['disable_bootloader_install'] = true if disable_bootloader_install
      params['force'] = true if ignore_nodes_deploying
      params['hook'] = true

      params
    end
  end # class Deployment
end
