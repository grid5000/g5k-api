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

require 'json'
require 'fileutils'

module Grid5000
  # Class for oarapi
  class OarApi
    include ApplicationHelper

    OAR_API_TIMEOUT = 300

    attr_accessor :base_uri, :user, :tls_options

    def get_job_walltime_change(job_id)
      http = call_oarapi(File.join(base_uri, job_id, 'details.json'), :get)
      if http.code.to_i == 404
        raise Errors::JobNotFound, job_id
      else
        JSON.parse(http.body)['walltime-change']
      end
    end

    def update_job_walltime_change(job_id, job_walltime)
      payload = job_walltime.as_json
      payload['method'] = 'walltime-change'
      payload.delete('errors')

      http = call_oarapi(File.join(base_uri, job_id + '.json'), :post, payload.to_json)
      case http.code.to_i
      when 404
        raise Errors::JobNotFound, job_id
      when 403
        raise Errors::JobForbidden, JSON.parse(http.body)['message']
      when 400
        raise Errors::JobBadRequest, JSON.parse(http.body)['message']
      else
        JSON.parse(http.body)['cmd_output']
      end
    end

    private

    def call_oarapi(uri, method, payload = nil)
      begin
        headers = { 'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Api-User-Cn' => user }
        http_request(method, uri, tls_options, OAR_API_TIMEOUT, headers, payload)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end
  end

  module Errors
    class OarApiError < StandardError
    end

    class JobNotFound < OarApiError
      def initialize(job_id)
        super("Job id '#{job_id}' cannot be found.")
      end
    end

    class JobForbidden < OarApiError
    end

    class JobBadRequest < OarApiError
    end
  end
end
