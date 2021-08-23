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

class JobsController < ApplicationController
  include Swagger::Blocks

  LIMIT = 50
  LIMIT_MAX = 500

  swagger_path "/sites/{siteId}/jobs" do
    operation :get do
      key :summary, 'List jobs'
      key :description, 'Fetch the list of all jobs for site. Jobs ordering is by ' \
        'descending date of submission.'
      key :tags, ['job']

      [:siteId, :offset, :limit, :jobQueue, :jobName, :jobState,
       :jobUser, :jobResources].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :JobCollection
          end
        end

        key :description, 'Job collection.'
      end
    end

    operation :post do
      key :summary, 'Submit job'
      key :description, "Submit a new job."
      key :tags, ['job']

      parameter do
        key :$ref, :siteId
      end

      request_body do
        key :description, 'Job submission payload.'
        key :required, true
        content 'application/json' do
          schema do
            key :'$ref', :JobSubmit
          end
        end
        content 'application/x-www-form-urlencoded' do
          schema do
            key :'$ref', :JobSubmit
          end
        end
      end

      response 201 do
        content :'plain/text'
        key :description, 'Job successfully created.'
        header :'Location' do
          key :description, 'Location of the new job.'
          schema do
            key :type, :string
          end
        end
      end
    end
  end

  # List jobs
  def index
    allow :get, :post; vary_on :accept

    offset = [(params[:offset] || 0).to_i, 0].max
    limit = [(params[:limit] || LIMIT).to_i, LIMIT_MAX].min
    jobs = OAR::Job.list(params)
    total = jobs.count(:all)

    params[:resources] = 'no' if params[:resources].nil?

    jobs = jobs.offset(offset).limit(limit).includes(:job_types, :job_events, :gantt)
    jobs_extra_hash = {}

    jobs.each do |job|
      job.links = links_for_item(job)
      if params[:resources] != 'no'
        jobs_extra_hash[job[:job_id]] = {}
        jobs_extra_hash[job[:job_id]][:resources_by_type] = job.resources_by_type
        jobs_extra_hash[job[:job_id]][:assigned_nodes] = job.assigned_nodes
      end
    end

    jobs_hash = jobs.as_json

    if params[:resources] != 'no'
      jobs_hash.each do |job|
        job.merge!(jobs_extra_hash[job[:uid]])
      end
    end

    result = {
      'total' => total,
      'offset' => offset,
      'items' => jobs_hash,
      'links' => links_for_collection
    }

    render_result(result)
  end

  swagger_path "/sites/{siteId}/jobs/{jobId}" do
    operation :get do
      key :summary, 'Get job'
      key :description, 'Fetch a specific job.'
      key :tags, ['job']

      [:siteId, :jobId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kitemjson) do
          schema do
            key :'$ref', :Job
          end
        end

        key :description, 'The job item.'
      end

      response 404 do
        content :'text/plain'
        key :description, 'Job not found.'
      end
    end

    operation :delete do
      key :summary, 'Delete job'
      key :description, 'Ask for deletion of job.'
      key :tags, ['job']

      [:siteId, :jobId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 202 do
        key :description, 'Job deletion accepted. Note that the deletion is not '\
          'immediate, the job can be poll until error state.'
        header :'Location' do
          key :description, 'Location of the job resource'
          schema do
            key :type, :string
          end
        end
      end
    end
  end

  # Display the details of a job
  def show
    allow :get, :delete; vary_on :accept
    job = OAR::Job.expanded.includes(:job_types, :job_events, :gantt).find(
      params[:id]
    )
    job.links = links_for_item(job)

    render_opts = { methods: %i[resources_by_type assigned_nodes] }
    render_result(job, render_opts)
  end

  # Delete a job. Client must be authenticated and must own the job.
  #
  # Delegates to the OAR API.
  def destroy
    ensure_authenticated!
    job = OAR::Job.find(params[:id])
    authorize!(job.user)

    uri = uri_to(
      site_path(
        params[:site_id]
      ) + "/internal/oarapi/jobs/#{params[:id]}.json",
      :out
    )
    tls_options = tls_options_for(:out)
    headers = { 'Accept' => api_media_type(:json),
                'X-Remote-Ident' => @credentials[:cn],
                'X-Api-User-Cn' => @credentials[:cn] }
    http = http_request(:delete, uri, tls_options, 180, headers)

    continue_if!(http, is: [200, 202, 204, 404])

    if http.code.to_i == 404
      raise NotFound, "Cannot find job##{params[:id]} on the OAR server"
    else
      response.header['X-Oar-Info'] = begin
                                        (
                                          JSON.parse(http.body)['oardel_output'] || ''
                                        ).split("\n").join(' ')
                                      rescue StandardError
                                        '-'
                                      end

      location_uri = uri_to(
        resource_path(params[:id]),
        :in, :absolute
      )

      render  plain: '',
              head: :ok,
              location: location_uri,
              status: 202
    end
  end

  # Create a new Job. Client must be authenticated.
  #
  # Delegates the request to the OAR API.
  def create
    ensure_authenticated!

    job = Grid5000::Job.new(job_params)
    Rails.logger.info "Received job = #{job.inspect}"
    raise BadRequest, "The job you are trying to submit is not valid: #{job.errors.join('; ')}" unless job.valid?

    job_to_send = job.to_hash(destination: 'oar-2.4-submission')
    Rails.logger.info "Submitting #{job_to_send.inspect}"

    uri = uri_to(
      site_path(params[:site_id]) + '/internal/oarapi/jobs.json', :out
    )
    tls_options = tls_options_for(:out)
    headers = { 'X-Remote-Ident' => @credentials[:cn],
                'X-Api-User-Cn' => @credentials[:cn],
                'Content-Type' => api_media_type(:json),
                'Accept' => api_media_type(:json) }

    http = http_request(:post, uri, tls_options, 180, headers, job_to_send.to_json)

    continue_if!(http, is: [201, 202])

    job_uid = JSON.parse(http.body)['id']
    location_uri = uri_to(
      resource_path(job_uid),
      :in, :absolute
    )

    job = OAR::Job.expanded.includes(:job_types, :job_events, :gantt).find(job_uid)
    job.links = links_for_item(job)

    render_opts = {
      methods: %i[resources_by_type assigned_nodes],
      location: location_uri,
      status: 201
    }
    render_result(job, render_opts)
  end

  protected

  def job_params
    # as g5k-api has readonly access to oar2 databases, do not attempt
    # to whitelist acceptable parameters to prevent mass_assignement
    # vulnerabilities
    params.permit!
  end

  def collection_path
    site_jobs_path(params[:site_id])
  end

  def parent_path
    site_path(params[:site_id])
  end

  def resource_path(id)
    File.join(collection_path, id.to_s)
  end

  def links_for_item(item)
    [
      {
        'rel' => 'self',
        'href' => uri_to(resource_path(item.uid)),
        'type' => api_media_type(:g5kitemjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(parent_path),
        'type' => api_media_type(:g5kitemjson)
      }
    ]
  end

  def links_for_collection
    [
      {
        'rel' => 'self',
        'href' => uri_to(collection_path),
        'type' => api_media_type(:g5kcollectionjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(parent_path),
        'type' => api_media_type(:g5kitemjson)
      }
    ]
  end
end
