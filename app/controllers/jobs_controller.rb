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
  LIMIT = 50
  LIMIT_MAX = 500

  # List jobs
  def index
    allow :get, :post; vary_on :accept

    offset = [(params[:offset] || 0).to_i, 0].max
    limit = [(params[:limit] || LIMIT).to_i, LIMIT_MAX].min

    jobs = OAR::Job.list(params)
    total = jobs.count

    jobs = jobs.offset(offset).limit(limit).includes(:job_types, :job_events, :gantt)

    jobs.each{|job|
      job.links = links_for_item(job)
    }

    result = {
      "total" => total,
      "offset" => offset,
      "items" => jobs,
      "links" => links_for_collection
    }

    respond_to do |format|
      format.g5kcollectionjson { render :json => result }
      format.json { render :json => result }
    end
  end

  # Display the details of a job
  def show
    allow :get, :delete; vary_on :accept
    job = OAR::Job.expanded.includes(:job_types, :job_events, :gantt).find(
      params[:id]
    )
    job.links = links_for_item(job)

    render_opts = {:methods => [:resources_by_type, :assigned_nodes]}
    respond_to do |format|
      format.g5kitemjson { render render_opts.merge(:json => job) }
      format.json { render render_opts.merge(:json => job)  }
    end
  end

  # Delete a job. Client must be authenticated and must own the job.
  #
  # Delegates to the OAR API.
  def destroy
    ensure_authenticated!
    job = OAR::Job.find(params[:id])
    authorize!(job.user)

    url = uri_to(
      site_path(
        params[:site_id]
      )+"/internal/oarapi/jobs/#{params[:id]}.json",
      :out
    )
    options=tls_options_for(url, :out)
    http = EM::HttpRequest.new(url,{:tls => options}).delete(
      :timeout => 5,
      :head => {
        'X-Remote-Ident' => @credentials[:cn],
        'Accept' => media_type(:json)
      }
    )

    continue_if!(http, :is => [200,202,204,404])

    if http.response_header.status == 404
      raise NotFound, "Cannot find job##{params[:id]} on the OAR server"
    else
      response.headers['X-Oar-Info'] = (
        JSON.parse(http.response)['oardel_output'] || ""
      ).split("\n").join(" ") rescue "-"

      location_uri = uri_to(
        resource_path(params[:id]),
        :in, :absolute
      )

      render  :text => "",
              :head => :ok,
              :location => location_uri,
              :status => 202
    end
  end

  # Create a new Job. Client must be authenticated.
  #
  # Delegates the request to the OAR API.
  def create
    ensure_authenticated!

    job = Grid5000::Job.new(payload)
    Rails.logger.info "Received job = #{job.inspect}"
    raise BadRequest, "The job you are trying to submit is not valid: #{job.errors.join("; ")}" unless job.valid?
    job_to_send = job.to_hash(:destination => "oar-2.4-submission")
    Rails.logger.info "Submitting #{job_to_send.inspect}"

    url = uri_to(
      site_path(params[:site_id])+"/internal/oarapi/jobs.json", :out
    )
    options=tls_options_for(url, :out)
    http = EM::HttpRequest.new(url, {:tls => options}).post(
      :timeout => 20,
      :body => job_to_send.to_json,
      :head => {
        'X-Remote-Ident' => @credentials[:cn],
        'Content-Type' => media_type(:json),
        'Accept' => media_type(:json)
      }    )
    continue_if!(http, :is => [201,202])

    job_uid = JSON.parse(http.response)['id']
    location_uri = uri_to(
      resource_path(job_uid),
      :in, :absolute
    )

    job = OAR::Job.expanded.find(
      job_uid,
      :include => [:job_types, :job_events, :gantt]
    )
    job.links = links_for_item(job)
    
    render_opts = {
      :methods => [:resources_by_type, :assigned_nodes],
      :location => location_uri,
      :status => 201
    }
    respond_to do |format|
      format.g5kitemjson { render render_opts.merge(:json => job) }
      format.json { render render_opts.merge(:json => job) }
    end
  end

  protected
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
        "rel" => "self",
        "href" => uri_to(resource_path(item.uid)),
        "type" => media_type(:g5kitemjson)
      },
      {
        "rel" => "parent",
        "href" => uri_to(parent_path),
        "type" => media_type(:g5kitemjson)
      }
    ]
  end

  def links_for_collection
    [
      {
        "rel" => "self",
        "href" => uri_to(collection_path),
        "type" => media_type(:g5kcollectionjson)
      },
      {
        "rel" => "parent",
        "href" => uri_to(parent_path),
        "type" => media_type(:g5kitemjson)
      }
    ]
  end
end
