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
  # Class representing environments
  class Environments
    include ApplicationHelper
    include Swagger::Blocks

    attr_accessor :base_uri, :user, :tls_options

    # Swagger doc
    swagger_component do
      parameter :environmentId do
        key :name, :environmentId
        key :in, :path
        key :description, 'ID of environment to fetch.'
        key :required, true
        schema do
          key :type, :string
        end
      end

      schema :Environment do
        key :required, [:uid, :arch, :name, :alias, :version, :description, :author,
                        :visibility, :destructive, :os, :image, :postinstalls,
                        :boot, :filesystem, :partition_type, :multipart, :user]

        property :uid do
          key :type, :string
          key :description, 'The Environment ID, composed of the name, the architecture, the version and the owner.'
          key :example, 'centos7-min_x86_64_2021090715_deploy'
        end

        property :name do
          key :type, :string
          key :description, 'The Environment name.'
          key :example, 'centos7-min'
        end

        property :alias do
          key :type, :string
          key :description, 'The Environment alias.'
          key :example, 'centos7-x64-min'
        end

        property :arch do
          key :type, :string
          key :description, 'The Environment targeted (CPU) architecture.'
          key :example, 'x86_64'
        end

        property :version do
          key :type, :integer
          key :description, 'The Environment version.'
          key :example, 2020120219
        end

        property :description do
          key :type, :string
          key :description, 'The Environment description.'
          key :example, 'centos 7 (7) for ppc64 - min'
        end

        property :author do
          key :type, :string
          key :description, 'The Environment author.'
          key :example, 'support-staff@lists.grid5000.fr'
        end

        property :visibility do
          key :type, :string
          key :description, 'The Environment visibility in kadeploy/kaenv tools. ' \
            'Can be private, shared or public'
          key :example, 'public'
        end

        property :destructive do
          key :type, :boolean
          key :description, 'If the environment has to be re-deployed at the end ' \
            'of job.'
          key :example, true
        end

        property :os do
          key :type, :string
          key :description, 'The OS of the environment, on Grid\'5000 generally linux ' \
            'or xen.'
          key :example, 'linux'
        end

        property :image do
          key :type, :object
          key :description, 'The image file containing the environment.'

          property :file do
            key :type, :string
            key :description, 'The path to the image file.'
            key :example, 'server:///grid5000/images/centos7-ppc64-min-2020120219.tgz'
          end

          property :kind do
            key :type, :string
            key :description, 'The kind of image.'
            key :example, 'tar'
            key :enum, ['tar','dd','fsa']
          end

          property :compression do
            key :type, :string
            key :description, 'The compression algorithm used to compress the image.'
            key :example, 'zstd'
          end
        end

        property :postinstalls do
          key :type, :array
          key :description, 'A list of postinstall to run.'

          items do
            key :type, :object

            property :archive do
              key :type, :string
              key :description, 'The path to the postinstall archive.'
              key :example, 'server:///grid5000/postinstalls/g5k-postinstall.tgz'
            end

            property :compression do
              key :type, :string
              key :description, 'The compression algorithm used to compress the' \
                'postinstall archive.'
              key :example, 'gzip'
            end

            property :script do
              key :type, :string
              key :description, 'The kind of image.'
              key :example, 'g5k-postinstall --net redhat'
            end
          end
        end

        property :boot do
          key :type, :object
          key :description, 'The environment \'s boot parameters.'

          key :type, :object

          property :kernel do
            key :type, :string
            key :description, 'The path to the kernel,inside the environment.'
            key :example, '/vmlinuz'
          end

          property :initrd do
            key :type, :string
            key :description, 'The path to the initrd, inside the environment.'
            key :example, '/initramfs.img'
          end

          property :kernel_params do
            key :type, :string
            key :description, 'The parameters given to the kernel when launching.'
            key :example, 'biosdevname=0 crashkernel=no'
          end
        end

        property :filesystem do
          key :type, :string
          key :description, 'The filesystem to use when formating the partition.'
          key :example, 'ext4'
        end

        property :partition_type do
          key :type, :string
          key :description, 'The partition type used when partitioning the disk.'
          key :example, '131'
        end

        property :multipart do
          key :type, :boolean
          key :description, 'If the environment image is a multi-partitioned archive.'
          key :example, false
        end

        property :user do
          key :type, :string
          key :description, 'The owner of the environment.'
          key :example, 'deploy'
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [
            {
              'rel': 'self',
              'href': '/%%API_VERSION%%/sites/grenoble/environments/centos7-ppc64-min_2020120219',
              'type': 'application/vnd.grid5000.item+json'
            },
            {
              'rel': 'parent',
              'href': '/%%API_VERSION%%/sites/grenoble/environments',
              'type': 'application/vnd.grid5000.collection+json'
            }
          ]
        end
      end

      schema :EnvironmentItems do
        key :required, [:items]
        property :items do
          key :type, :array
          items do
            key :'$ref', :Environment
          end
        end
      end

      schema :EnvironmentCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :'$ref', :EnvironmentItems
          end
          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [
                {
                  'rel': 'self',
                  'href': '/%%API_VERSION%%/sites/grenoble/environments',
                  'type': 'application/vnd.grid5000.collection+json'
                },
                {
                  'rel': 'parent',
                  'href': '/%%API_VERSION%%/sites/grenoble',
                  'type': 'application/vnd.grid5000.item+json'
                }
              ]
            end
          end
        end
      end
    end

    # List all environments. This include public environments, and current user's
    # environments. When user is anonymous, only list the public environments.
    def list(params = nil)
      kadeploy_params = {}
      latest_only = if params[:action] == 'show'
                      'no'
                    else
                      params&.has_key?('latest_only') ? params['latest_only'] : 'yes'
                    end

      username = params['user'] if params&.has_key?('user')
      name = params['name'] if params&.has_key?('name')
      arch = params['arch'] if params&.has_key?('arch')

      kadeploy_params['last'] = true unless latest_only == 'no' || latest_only == 'false'
      kadeploy_params['username'] = username if username

      http = call_kadeploy_environments(kadeploy_params)

      # When a username is present in the query's parameters, we only need to
      # make one request to kadeploy to retrieve the user's environments.
      # If user is anonymous (from X-Api-User-Cn), we only request kadeploy for
      # the public environments.
      if username || user == 'anonymous'
        environments = JSON.parse(http.body)
      else
        environments = JSON.parse(http.body)
        kadeploy_params['username'] = user
        http_user = call_kadeploy_environments(kadeploy_params)
        environments.push(JSON.parse(http_user.body)).flatten!
      end

      environments.map! { |e| format_environment(e) }
      environments.select! { |e| e['name'] == name } if name
      environments.select! { |e| e['arch'] == arch } if arch

      environments
    end

    # Get a specific environment, by it's uid
    def find(uid, params)
      environments = list(params)
      environments.select { |e| e['uid'] == uid }
    end

    # Make some modification to an environment
    def format_environment(env)
      env['uid'] = env.slice('name','arch','version','user').values.join('_')
      env
    end

    private

    def call_kadeploy_environments(params = nil)
      uri = URI(base_uri)
      uri.query = URI.encode_www_form(params) if params

      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Api-User-Cn' => user }
        http_request(:get, uri, tls_options, 10, headers)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end
  end
end
