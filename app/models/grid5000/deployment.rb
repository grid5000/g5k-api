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
    include Swagger::Blocks
    include ApplicationHelper

    attr_accessor :links
    # Ugly hack to make the communication between the controller and the model possible
    attr_accessor :base_uri, :user, :tls_options
    serialize :nodes, JSON
    serialize :result, JSON

    validates_presence_of :user_uid, :site_uid, :environment, :nodes
    validates_uniqueness_of :uid, case_sensitive: true

    before_create do
      self.created_at ||= Time.now.to_i
    end

    before_save do
      self.updated_at = Time.now.to_i
      if uid.nil?
        errors.add(:uid, 'must be set')
        throw(:abort)
      end
      errors.empty?
    end

    # Swagger doc
    swagger_component do
      parameter :deploymentId do
        key :name, :deploymentId
        key :in, :path
        key :description, 'ID of deployment to fetch.'
        key :required, true
        schema do
          key :type, :string
        end
      end

      parameter :deployReverse do
        key :name, :reverse
        key :in, :query
        key :description, 'Return deployment collection in reversed creation order. '\
          'By default, deployments are listed in descending creation date order.'
        key :required, false
        schema do
          key :type, :boolean
        end
      end

      parameter :deployStatus do
        key :name, :status
        key :in, :query
        key :description, 'Filter the deployment collection with a specific deployment '\
          'state (waiting, processing, canceled, terminated, error).'
        key :required, false
        schema do
          key :type, :string
        end
      end

      parameter :deployUser do
        key :name, :user
        key :in, :query
        key :description, 'Filter the deployment collection with a specific deployment '\
          ' owner.'
        key :required, false
        schema do
          key :type, :string
        end
      end

      schema :DeploymentCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :'$ref', :DeploymentItems
          end
          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/%%API_VERSION%%/sites/grenoble/deployments',
                  'type':'application/vnd.grid5000.item+json'
                },
                {
                  'rel':'parent',
                  'href':'/%%API_VERSION%%/sites/grenoble',
                  'type':'application/vnd.grid5000.item+json'
                }]
            end
          end
        end
      end

      schema :DeploymentItems do
        key :required, [:items]
        property :items do
          key :type, :array
          items do
            key :'$ref', :Deployment
          end
        end
      end

      schema :Deployment do
        key :required, [:uid, :site_uid, :user_uid, :environment, :status,
                        :nodes, :result, :created_at, :links]

        property :uid do
          key :type, :string
          key :description, 'The unique identifier (UUID format) of the deployment.'
          key :example, 'D-967b6741-5bde-4023-a071-a4cf28da4d'
        end
        property :site_uid do
          key :type, :string
          key :description, 'The site deployment site.'
          key :example, 'grenoble'
        end
        property :user_uid do
          key :type, :string
          key :description, 'The deployment owner.'
          key :example, 'user'
        end
        property :environment do
          key :type, :string
          key :description, 'The deployed environment.'
          key :example, 'debian11-std'
        end
        property :status do
          key :type, :string
          key :description, 'The deployment status (waiting, processing, canceled, '\
            'terminated, error).'
          key :example, 'debian11-std'
        end
        property :nodes do
          key :type, :array
          items do
            key :type, :string
            key :format, :hostname
          end

          key :description, 'An array of nodes FQDN on which deployment is (or was) '\
            'runnning.'
          key :example, ['paramount-1.rennes.grid5000.fr',
                         'paradent-8.rennes.grid5000.fr']
        end
        property :result do
          key :type, :object
          key :description, 'Results of deployment, for each node.'
          key :example, {"dahu-9.grenoble.grid5000.fr": {
                          "macro":nil, "micro":nil, "state":"OK"}
                        }
        end
        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
             'href':'/%%API_VERSION%%/sites/grenoble/deployments/D-967b6741-5bde-4023-a071-a4cf28da4d',
             'type':'application/vnd.grid5000.item+json'
            },
            {
              'rel':'parent',
              'href':'/%%API_VERSION%%/sites/grenoble',
              'type':'application/vnd.grid5000.item+json'
            }]
        end
      end

      schema :DeploymentSubmit do
        key :required, [:nodes, :environment]

        property :nodes do
          key :type, :array
          items do
            key :type, :string
            key :format, :hostname
          end
          key :description, 'An array of nodes FQDN on which you want to deploy '\
            'the new environment image.'
          key :example, ['paramount-1.rennes.grid5000.fr',
                         'paradent-8.rennes.grid5000.fr']
        end
        property :environment do
          key :type, :string
          key :description, 'The name (or alias) of an environment that belongs to you or '\
            'whose visibility is public (e.g. debian10-x64-base), OR the name of '\
            'an environment that is owned by another user but with visibility '\
            'set to shared (e.g. env-name@user-uid), OR the HTTP or HTTPS URL '\
            'to a file describing your environment (this has the advantage that '\
            'you do not need to register it in the kadeploy database).'
          key :example, 'debian10-min'
        end
        property :key do
          key :type, :string
          key :description, 'The content of your SSH public key file or authorized_keys '\
            '(to provide multiple keys). This can also be an HTTP URL to your SSH public '\
            'key. That key will be dropped in the authorized_keys file of the nodes '\
            'after deployment, so that you can SSH into them as root.'
          key :example, 'https://public.grenoble.grid5000.fr/~username/deploy_key'
        end
        property :version do
          key :type, :integer
          key :description, 'Version of the environment to use.'
          key :example, 1
        end
        property :arch do
          key :type, :string
          key :description, 'Architecture of the environment to use.'
          key :enum, ['x86_64', 'ppc64le', 'aarch64']
          key :example, 'x86_64'
        end
        property :block_device do
          key :type, :string
          key :description, 'The block device to deploy on.'
          key :example, 'disk1'
        end
        property :partition_label do
          key :type, :string
          key :description, 'The partition label to deploy on.'
          key :example, 'TMP'
        end
        property :vlan do
          key :type, :integer
          key :description, "Configure the nodes' vlan."
          key :example, 3
        end
        property :reformat_tmp do
          key :type, :string
          key :description, 'Reformat the /tmp partition with the given filesystem type.'
          key :example, 'ext4'
        end
        property :disable_disk_partitioning do
          key :type, :boolean
          key :description, 'Disable the disk partitioning.'
          key :default, false
          key :example, true
        end
        property :disable_bootloader_install do
          key :type, :boolean
          key :description, 'Disable the automatic installation of a bootloader '\
            'for a Linux based environment.'
          key :default, false
          key :example, true
        end
        property :ignore_nodes_deploying do
          key :type, :boolean
          key :description, "Don't complain when deploying on nodes tagged as "\
            "'currently deploying'."
          key :default, false
          key :example, true
        end
        property :reboot_classical_timeout do
          key :type, :integer
          key :description, "Overwrite the default timeout for classical reboots."
          key :example, 500
        end
        property :reboot_kexec_timeout do
          key :type, :integer
          key :description, "Overwrite the default timeout for kexec reboots."
          key :example, 400
        end
      end
    end

    def to_param
      uid
    end

    # Experiment states
    state_machine :status, initial: :waiting do
      before_transition processing: :canceled, do: :cancel_workflow!
      before_transition waiting: :processing, do: :launch_workflow!

      event :launch do
        transition waiting: :processing
      end
      event :process do
        transition processing: :processing
      end
      event :cancel do
        transition processing: :canceled
      end
      event :terminate do
        transition processing: :terminated
      end
      event :failed do
        transition processing: :error
      end
    end

    def active?
      status?(:processing)
    end

    validate do
      errors.add :nodes, 'must be a non-empty list of node FQDN' unless nodes.is_a?(Array) && nodes.length > 0
    end

    def processing?
      status.nil? || status == 'processing'
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

        scheme = begin
                   URI.parse(value).scheme
                 rescue StandardError
                   nil
                 end
        next unless scheme.nil?

        filename = [
          user_uid, attribute, Digest::SHA1.hexdigest(value)
        ].join('-')
        # ensure the directory exists...
        FileUtils.mkdir_p(tmpfiles_dir)
        # and write the file to that location
        File.open("#{tmpfiles_dir}/#{filename}", 'w') { |f| f.write(value) }
        uri = "#{base_uri}/#{filename}"
        send("#{attribute}=".to_sym, uri)
      end
    end

    def cancel_workflow!
      raise 'cancel_workflow!' if !user || !base_uri # Ugly hack

      begin
        headers = { 'X-Remote-Ident' => user }
        uri = File.join(base_uri, uid)
        http_request(:delete, uri, tls_options, 15, headers)
      rescue StandardError
        error("Unable to contact #{File.join(base_uri, uid)}")
        raise output + "\n"
      end

      # Not checked since it avoid touch! to cancel the deployment
      # unless %w{200 201 202 204}.include?(http.response_header.code.to_s)
      #  fail
      #  raise "The deployment no longer exists on the Kadeploy server"
      # end

      true
    end

    def launch_workflow!
      raise 'launch_workflow!' if !user || !base_uri # Ugly hack

      params = to_hash
      # The environment was specified as an URL to a description file
      if params['environment'].empty?
        scheme = URI.parse(environment).scheme
        case scheme
        when 'http', 'https'
          begin
            http = http_request(:get, environment, tls_options, 10)
            params['environment'] = YAML.load(http.body)
            params['environment']['kind'] = 'anonymous'
          rescue StandardError => e
            raise "Error fetching the image description file: #{e.class.name}, #{e.message}"
          end
        else
          raise "Error fetching the image description file: #{scheme} protocol not supported yet"
        end
      else
        params['environment']['kind'] = 'database'
      end
      Rails.logger.info "Submitting: #{params.inspect} to #{base_uri}"

      begin
        headers = { 'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
                    'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user }
        http = http_request(:post, base_uri, tls_options, 20, headers, params.to_json)
      rescue StandardError
        error("Unable to contact #{base_uri}")
        raise output + "\n"
      end

      if %w[200 201 202 204].include?(http.code.to_s)
        update_attribute(:uid, JSON.parse(http.body)['wid'])
      else
        # Cannot continue since :uid is not set
        error
        kaerror_exception, kaerror_msg = get_kaerror(http, http.header)
        raise kaerror_exception, kaerror_msg
      end

      true
    end

    def touch!
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user }
        uri = File.join(base_uri, uid)
        http = http_request(:get, uri, tls_options, 10, headers)
      rescue StandardError
        error("Unable to contact #{File.join(base_uri, uid)}")
        raise output + "\n"
      end

      if %w[200 201 202 204].include?(http.code.to_s)
        item = JSON.parse(http.body)

        if item['error']
          begin
            headers = { 'X-Remote-Ident' => user }
            uri = File.join(base_uri, uid, 'error')
            http = http_request(:get, uri, tls_options, 15, headers)
          rescue StandardError
            kaerror_exception, _ = get_kaerror(http, http.header)
            error("Unable to contact #{File.join(base_uri, uid, 'error')}")
            raise kaerror_exception, output
          end

          return
        else
          begin
            uri = File.join(base_uri, uid, 'state')
            http = http_request(:get, uri, tls_options, 15, headers)
          rescue StandardError
            error("Unable to contact #{File.join(base_uri, uid, 'state')}")
            raise output + "\n"
          end

          res = JSON.parse(http.body)
          # Ugly compatibility hack
          res.each_pair do |node, _stat|
            res[node]['state'] = res[node]['state'].upcase
          end
          self.result = res
        end

        if item['done']
          terminate
        else
          process
        end
      else
        error('The deployment no longer exists on the Kadeploy server')
      end
    end

    # TODO: look at continue_if! helper if it can be used in this model. This
    # will allow to always return the same HTTP return code as Kadeploy's one,
    # and make custom treatments when needed.
    def get_kaerror(resp, hdr)
      if hdr['X_APPLICATION_ERROR_CODE'] && hdr['X_APPLICATION_ERROR_INFO']
        [Errors::Kadeploy::ServerError, "Kadeploy error ##{hdr['X_APPLICATION_ERROR_CODE']}: #{Base64.strict_decode64(hdr['X_APPLICATION_ERROR_INFO'])}"]
      elsif resp.code.to_i == 400
        [Errors::Kadeploy::BadRequest, resp.body]
      else
        # Before the introduction of Errors::Kadeploy errors module, the controller only responded
        # with 500 error. This is why this stays the default, new Errors::Kadeploy types need to
        # be added if the time come to handle more cases.
        [Errors::Kadeploy::ServerError, resp.body]
      end
    end

    def error(msg = nil)
      if msg
        self.output = msg
      end

      # Delete the workflow from the kadeploy server
      cancel_workflow! if uid

      failed
    end

    def as_json(*)
      attributes.merge(links: links).reject { |k, v| v.nil? || k == 'id' }
    end

    def to_hash
      params = {
        'environment' => {}
      }
      if URI.parse(environment).scheme.nil?
        env_name, env_user = environment.split('@')
        params['environment'] = { 'name' => env_name }
        params['environment']['user'] = env_user if env_user
        params['environment']['version'] = version.to_s if version
        params['environment']['arch'] = arch.to_s if arch
      end
      params['ssh_authorized_keys'] = key if key
      params['nodes'] = nodes.dup
      params['deploy_part'] = partition_label.to_s if partition_label
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

  module Errors
    module Kadeploy
      class ServerError < StandardError; end
      class BadRequest < StandardError; end
    end
  end
end
