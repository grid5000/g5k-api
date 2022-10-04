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

module Grid5000
  # Computes the URI to a specific path.
  # X-Api-root-Path is the entry point for all versions of the API
  # X-Api-version is the version string by which the server is reached
  # X-Api-Path-Prefix was used in the transition from sid/grid5000/sites to /sid/sites
  #   and is kept should the API serve more than on platform
  # X-Api-Mount-Path (subset of the API path to take out of the URI path).
  #   It is the entry point to access this service for a
  #   given version. To use if a server does not wish to show the top level
  #   hieararchy exposed by the services, for example to only publish the
  #   resources of a single site (https://rennes.g5k/ ony giving access to
  #   resources under the /sites/rennes path
  class Router
    def initialize(where)
      @where = where
    end

    def call(_params, request)
      self.class.uri_to(request, @where, :in, :absolute)
    end

    class << self
      def api_version(request)
        if request.env['HTTP_X_API_VERSION'].blank?
          nil
        else
          File.join('/', (request.env['HTTP_X_API_VERSION'] || ''))
        end
      end

      def uri_to(request, path, in_or_out = :in, relative_or_absolute = :relative)
        root_path = if request.env['HTTP_X_API_ROOT_PATH'].blank? || in_or_out == :out
                      nil
                    else
                      File.join('/', (request.env['HTTP_X_API_ROOT_PATH'] || ''))
                    end


        path_prefix = if request.env['HTTP_X_API_PATH_PREFIX'].blank?
                        nil
                      else
                        File.join('/', (request.env['HTTP_X_API_PATH_PREFIX'] || ''))
                      end

        mount_path = if request.env['HTTP_X_API_MOUNT_PATH'].blank?
                       nil
                     else
                       File.join('/', (request.env['HTTP_X_API_MOUNT_PATH'] || ''))
                     end

        mounted_path = path
        mounted_path.gsub!(/^#{mount_path}/, '') unless mount_path.nil?
        mounted_path = '/' if mounted_path.blank?
        uri = File.join('/', *[root_path, api_version(request), path_prefix, mounted_path].compact)
        uri = '/' if uri.blank?
        # bug ref 7360 - for correct URI construction
        if in_or_out == :out || relative_or_absolute == :absolute
          root_uri = URI(base_uri(in_or_out))
          root_path = if root_uri.path.blank?
                        ''
                      else
                        root_uri.path
                      end

          uri = URI.join(root_uri, root_path + uri).to_s
        end
        uri
      end

      # FIXME: move Rails.config to Grid5000.config
      def base_uri(in_or_out = :in)
        Rails.my_config("base_uri_#{in_or_out}".to_sym)
      end

      def tls_options_for(in_or_out = :in)
        tls_options = {}
        %i[cert_chain_file private_key_file verify_peer fail_if_no_peer_cert
           cipher_list ecdh_curve dhparam ssl_version].each do |tls_param|
          config_key = ("uri_#{in_or_out}_" + tls_param.to_s).to_sym
          tls_options[tls_param] = Rails.my_config(config_key) if Rails.my_config(config_key)
        end
        tls_options
      end

      def http_request(method, uri, tls_options, timeout = nil, headers = {}, body = nil)
        uri = URI(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = timeout || 5
        http.use_ssl = true if uri.scheme == 'https'
        http.max_retries = 0

        if tls_options.present?
          http.cert = OpenSSL::X509::Certificate.new(File.read(tls_options[:cert_chain_file]))
          http.key = OpenSSL::PKey::RSA.new(File.read(tls_options[:private_key_file]))
          http.verify_mode = tls_options[:verify_peer].constantize if tls_options[:verify_peer]
        end

        request = case method
                  when :post
                    Net::HTTP::Post.new(uri, headers)
                  when :get
                    Net::HTTP::Get.new(uri, headers)
                  when :delete
                    Net::HTTP::Delete.new(uri, headers)
                  when :put
                    Net::HTTP::Put.new(uri, headers)
                  else
                    raise "Unknown http method: #{method}"
                  end

        request['User-Agent'] = 'g5k-api'
        request.body = body if body
        Rails.logger.info "     Launching http request to #{uri}, with method: #{method}"
        Rails.logger.info "     headers: #{headers}"
        Rails.logger.info "     body: #{body}" if body
        http.request(request)
      end
    end
  end
end
