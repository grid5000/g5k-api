class JobsWalltimeController < ApplicationController
  include Swagger::Blocks

  OAR_API_TIMEOUT = 300

  before_action :load_oarapi

  swagger_path "/sites/{siteId}/jobs/{jobId}/walltime" do
    operation :get do
      key :summary, 'Get walltime change'
      key :description, 'Fetch walltime change for a specific job.'
      key :tags, ['job']

      [:siteId, :jobId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kitemjson) do
          schema do
            key :'$ref', :JobWalltime
          end
        end

        key :description, 'The job walltime item.'
      end

      response 404 do
        content :'text/plain'
        key :description, 'Job not found.'
      end
    end

    operation :post do
      key :summary, 'Submit walltime change'
      key :description, 'Submit a job walltime change for a specific job.'
      key :tags, ['job']

      [:siteId, :jobId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      request_body do
        key :description, 'Job walltime change submission payload.'
        key :required, true
        content 'application/json' do
          schema do
            key :'$ref', :JobWalltimeSubmit
          end
        end
      end

      response 202 do
        key :description, 'Job walltime change request was created.'
      end

      response 400 do
        content :'text/plain'
        key :description, 'Job walltime change request is not right.'
      end

      response 403 do
        content :'text/plain'
        key :description, 'Job walltime change cannot be made for this job id.'
      end

      response 404 do
        content :'text/plain'
        key :description, 'Job not found.'
      end
    end
  end

  # Show current walltime change status, client must be authenticated
  #
  # Delegates the request to the OAR API.
  def show
    allow :get
    ensure_authenticated!

    result = @oarapi.get_job_walltime_change(params[:id])
    result['uid'] = params[:id].to_i
    result['links'] = links_for_item(result)

    render_result(result)
  end

  # Place a walltime change request, client must be authenticated
  #
  # Delegates the request to the OAR API.
  def update
    allow :post
    ensure_authenticated!

    unless request.content_type == 'application/json'
      raise UnsupportedMediaType, request.content_type
    end

    job_walltime = Grid5000::JobWalltime.new(job_walltime_params)
    Rails.logger.info "Received job walltime change = #{job_walltime.inspect}"
    if !job_walltime.valid?
      raise BadRequest,
        "The job walltime change you are trying to submit is not valid: #{job_walltime.errors.join('; ')}"
    end

    result = @oarapi.update_job_walltime_change(params[:id], job_walltime)
    location_uri = uri_to(resource_path(params[:id]), :in, :absolute)

    render_opts = {
      location: location_uri,
      status: 202
    }
    render_result(result, render_opts)
  end


  protected

  def job_walltime_params
    params.permit(:walltime, :delay_next_jobs, :force, :whole, :timeout)
  end

  private

  def api_path
    uri_to(
      File.join(
        site_path(params[:site_id]),
        '/internal/oarapi/jobs'
      ),
      :out
    )
  end

  def load_oarapi
    @oarapi = Grid5000::OarApi.new
    @oarapi.tls_options = tls_options_for(:out)
    @oarapi.base_uri = api_path
    @oarapi.user = @credentials[:cn]
  end

  def collection_path
    site_jobs_path(params[:site_id])
  end

  def parent_path
    site_job_path(params[:site_id])
  end

  def resource_path(id)
    File.join(collection_path, id.to_s, 'walltime')
  end

  def links_for_item(item)
    [
      {
        'rel' => 'self',
        'href' => uri_to(resource_path(item['uid'])),
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
