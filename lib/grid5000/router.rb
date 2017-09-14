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
  # X-Api-Path-Prefix is the entry point to access this service for a
  #   given version. To use if a server does not wish to show the top level
  #   hieararchy exposed by the services, for example to only publish the
  #   resources of a single site (https://rennes.g5k/ ony giving access to
  #   resources under the /sites/rennes path
  # X-Api-Mount-Path (subset of the API path to take out of the URI path).
  class Router
    
    def initialize(where)
      @where = where
    end
    
    def call(params, request)
      self.class.uri_to(request, @where, :in, :absolute)
    end
    
    class << self
      def uri_to(request, path, in_or_out = :in, relative_or_absolute = :relative)
        root_path = if request.env['HTTP_X_API_ROOT_PATH'].blank?
          nil
        else
          File.join("/", (request.env['HTTP_X_API_ROOT_PATH'] || ""))
        end # root_path = if request.env['HTTP_X_API_ROOT_PATH'].blank?

        api_version = if request.env['HTTP_X_API_VERSION'].blank?
          nil
        else
          File.join("/", (request.env['HTTP_X_API_VERSION'] || ""))
        end # api_version = if request.env['HTTP_X_API_VERSION'].blank?

        path_prefix = if request.env['HTTP_X_API_PATH_PREFIX'].blank?
          nil
        else
          File.join("/", (request.env['HTTP_X_API_PATH_PREFIX'] || ""))
        end # path_prefix = if request.env['HTTP_X_API_PATH_PREFIX'].blank?

        mount_path = if request.env['HTTP_X_API_MOUNT_PATH'].blank?
          nil
        else
          File.join("/", (request.env['HTTP_X_API_MOUNT_PATH'] || ""))
        end # mount_path = if request.env['HTTP_X_API_MOUNT_PATH'].blank?

        mounted_path=path
        mounted_path.gsub!(/^#{mount_path}/,'') unless mount_path.nil?
        mounted_path='/' if mounted_path.blank?
        uri = File.join("/", *[root_path, api_version, path_prefix, mounted_path].compact)
        uri = "/" if uri.blank?
        # abasu / dmargery - bug ref 7360 - for correct URI construction
        if in_or_out == :out || relative_or_absolute == :absolute
          root_uri=URI(base_uri(request, in_or_out))
          if root_uri.path.blank?
            root_path=''
          else	
            root_path=root_uri.path+'/'
          end # if root_uri.path.blank?
          uri = URI.join(root_uri, root_path+uri).to_s
        end # if in_or_out == :out || relative_or_absolute == :absolute
        uri
      end # def uri_to()

      # FIXME: move Rails.config to Grid5000.config
      def base_uri(request, in_or_out = :in)
        if request.env.has_key?('HTTP_X_FORWARDED_HOST') && in_or_out == :in
          hosts=request.env['HTTP_X_FORWARDED_HOST'].split(',')
          frontend_with_port=hosts[0]
          frontend=frontend_with_port.split(':').first
          if Rails.my_config(frontend.to_sym)
            Rails.logger.debug "Using config defined protocoli to compute base_uri :in"
            "#{Rails.my_config(frontend.to_sym)}://#{frontend_with_port}"
          else
            Rails.logger.debug "Did not find configuration entry for #{frontend.to_sym}, extracted from #{hosts}: redirecting to https"
            "https://#{frontend_with_port}"
          end
        else
          Rails.logger.debug("HTTP_X_FORWARDED_HOST not present: suspect server was not reached through a proxy") if in_or_out == :in
          Rails.my_config("base_uri_#{in_or_out}".to_sym)
        end
      end
    end
  end
end
