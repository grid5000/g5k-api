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
      continue_if!(http, is: [200, 404])

      if http.code.to_i == 404
        raise Errors::OarApi::NotFound, job_id
      else
        JSON.parse(http.body)['walltime-change']
      end
    end

    def update_job_walltime_change(job_id, job_walltime)
      payload = job_walltime.as_json
      payload['method'] = 'walltime-change'
      payload.delete('errors')

      http = call_oarapi(File.join(base_uri, job_id + '.json'), :post, payload.to_json)
      continue_if!(http, is: [201, 202, 400, 403, 404])

      case http.code.to_i
      when 404
        raise Errors::OarApi::NotFound, job_id
      when 403
        raise Errors::OarApi::Forbidden, JSON.parse(http.body)['message']
      when 400
        raise Errors::OarApi::BadRequest, JSON.parse(http.body)['message']
      else
        JSON.parse(http.body)['cmd_output']
      end
    end

    def create_job(job)
      http = call_oarapi(base_uri + '.json', :post, job.to_json)
      continue_if!(http, is: [201, 202])

      http.body
    end

    def destroy_job(job_id)
      http = call_oarapi(File.join(base_uri, job_id) + '.json', :delete)
      continue_if!(http, is: [200, 202, 204, 404])

      if http.code.to_i == 404
        raise Errors::OarApi::NotFound, job_id
      end

      http.body
    end

    private

    def call_oarapi(uri, method, payload = nil)
      begin
        headers = { 'Content-Type'   => Mime::Type.lookup_by_extension(:json).to_s,
                    'Accept'         => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user,
                    'X-Api-User-Cn'  => user}
        http_request(method, uri, tls_options, OAR_API_TIMEOUT, headers, payload)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end
  end

  module Errors
    module OarApi
      class NotFound < StandardError
        def initialize(job_id)
          super("Job id '#{job_id}' cannot be found.")
        end
      end

      class Forbidden < StandardError
      end

      class BadRequest < StandardError
      end
    end
  end
end
