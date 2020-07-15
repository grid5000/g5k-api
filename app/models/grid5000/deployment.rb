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
    include ApplicationHelper

    attr_accessor :links
    # Ugly hack to make the communication between the controller and the model possible
    attr_accessor :base_uri, :user, :tls_options
    serialize :nodes, JSON
    serialize :result, JSON

    validates_presence_of :user_uid, :site_uid, :environment, :nodes
    validates_uniqueness_of :uid, :case_sensitive => true

    before_create do
      self.created_at ||= Time.now.to_i
    end

    before_save do
      self.updated_at = Time.now.to_i
      if uid.nil?
        errors.add(:uid, "must be set")
        throw(:abort)
      end
      errors.empty?
    end

    def to_param
      uid
    end

    # Experiment states
    state_machine :status, :initial => :waiting do
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
      event :failed do
        transition :processing => :error
      end
    end

    def active?
      status?(:processing)
    end

    validate do
      errors.add :nodes, "must be a non-empty list of node FQDN" unless (nodes.kind_of?(Array) && nodes.length > 0)
    end

    def processing?
      status.nil? || status == "processing"
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
    end

    def cancel_workflow!
      raise "cancel_workflow!" if !user or !base_uri # Ugly hack

      begin
        headers = { 'X-Remote-Ident' => user }
        uri = File.join(base_uri, uid)
        http_request(:delete, uri, tls_options, 15, headers)
      rescue
        error("Unable to contact #{File.join(base_uri,uid)}")
        raise self.output+"\n"
      end

      # Not checked since it avoid touch! to cancel the deployment
      #unless %w{200 201 202 204}.include?(http.response_header.code.to_s)
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
            http = http_request(:get, environment, tls_options, 10)
            params['environment'] = YAML.load(http.body)
            params['environment']['kind'] = 'anonymous'
          rescue => e
            raise "Error fetching the image description file: #{e.class.name}, #{e.message}"
          end
        else
          raise "Error fetching the image description file: #{scheme} protocol not supported yet"
        end
      else
        params['environment']['kind'] = 'database'
      end
      Rails.logger.info "Submitting: #{params.inspect} to #{base_uri}"

      headers = { 'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
                  'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                  'X-Remote-Ident' => user,}
      http = http_request(:post, base_uri, tls_options, 20, headers, params.to_json)

      unless %w{200 201 202 204}.include?(http.code.to_s)
        error("Unable to contact #{base_uri}")
        raise self.output+"\n"
      end

      if %w{200 201 202 204}.include?(http.code.to_s)
        update_attribute(:uid, JSON.parse(http.body)['wid'])
      else
        error(get_kaerror(http,http.header))
        # Cannot continue since :uid is not set
        raise self.output+"\n"
      end

      true
    end

    def touch!
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user}
        uri = File.join(base_uri, uid)
        http = http_request(:get, uri, tls_options, 10, headers)
      rescue
        error("Unable to contact #{File.join(base_uri,uid)}")
        raise self.output+"\n"
      end

      if %w{200 201 202 204}.include?(http.code.to_s)
        item = JSON.parse(http.body)

        unless item['error']
          begin
            uri = File.join(base_uri, uid, 'state')
            http = http_request(:get, uri, tls_options, 15, headers)
          rescue
            error("Unable to contact #{File.join(base_uri,uid, 'state')}")
            raise self.output+"\n"
          end

          res = JSON.parse(http.body)
          # Ugly compatibility hack
          res.each_pair do |node, _stat|
            res[node]['state'] = res[node]['state'].upcase
          end
          self.result = res
        else
          begin
            headers = { 'X-Remote-Ident' => user }
            uri = File.join(base_uri, uid, 'error')
            http = http_request(:get, uri, tls_options, 15, headers)
          rescue
            error(get_kaerror(http,http.header))
            error("Unable to contact #{File.join(base_uri,uid,'error')}")
            raise self.output + "\n"
          end

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
      if hdr['X_APPLICATION_ERROR_CODE'] && hdr['X_APPLICATION_ERROR_INFO']
        "Kadeploy error ##{hdr['X_APPLICATION_ERROR_CODE']}: #{Base64.strict_decode64(hdr['X_APPLICATION_ERROR_INFO'])}"
      else
        "HTTP error ##{resp.code}: #{resp.body}"
      end
    end

    def error(msg)
      self.output = msg

      # Delete the workflow from the kadeploy server
      cancel_workflow! if uid

      failed
    end

    def as_json(*)
      attributes.merge(:links => links).reject{|k,v| v.nil? || k=="id"}
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
  end
end
