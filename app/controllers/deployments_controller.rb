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

class DeploymentsController < ApplicationController
  include Swagger::Blocks

  LIMIT = 50
  LIMIT_MAX = 500

  swagger_path "/sites/{siteId}/deployments" do
    operation :get do
      key :summary, 'List deployments'
      key :description, "Fetch the list of all the deployments created for site. " \
        "The default pagination will return #{LIMIT} deployments, it is possible to " \
        "return up to #{LIMIT_MAX} items by using the `limit` parameter. " \
        "Use the `offset` parameter to paginate through deployments."
      key :tags, ['deployment']

      parameter do
        key :$ref, :limit
        schema do
          key :default, LIMIT
        end
      end

      [:siteId, :offset, :deployReverse, :deployStatus, :deployUser].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :DeploymentCollection
          end
        end

        key :description, 'Deployment collection.'
      end
    end

    operation :post do
      key :summary, 'Submit deployment'
      key :description, "Submit a new deployment (requires a job deploy reservation)."
      key :tags, ['deployment']

      parameter do
        key :$ref, :siteId
      end

      request_body do
        key :description, 'Deployment creation object.'
        key :required, true
        content 'application/json' do
          schema do
            key :'$ref', :DeploymentSubmit
          end
        end
        content 'application/x-www-form-urlencoded' do
          schema do
            key :'$ref', :DeploymentSubmit
          end
        end
      end

      response 201 do
        content :'plain/text'
        key :description, 'Deployment successfully created.'
        header :'Location' do
          key :description, 'Location of the new deployment resource.'
          schema do
            key :type, :string
          end
        end
      end
    end
  end

  # List deployments
  def index
    allow :get, :post; vary_on :accept

    offset = [(params[:offset] || 0).to_i, 0].max
    limit = [(params[:limit] || LIMIT).to_i, LIMIT_MAX].min
    order = 'DESC'
    order = 'ASC' if params[:reverse] && params[:reverse].to_s == 'true'

    items = Grid5000::Deployment.order("created_at #{order}")
    items = items.where(user_uid: params[:user]) if params[:user]
    items = items.where(status: params[:status]) if params[:status]

    total = items.count

    items = items.offset(offset).limit(limit)

    items.each do |item|
      item.links = links_for_item(item)
    end

    result = {
      'total' => total,
      'offset' => offset,
      'items' => items,
      'links' => links_for_collection
    }

    render_result(result)
  end

  swagger_path "/sites/{siteId}/deployments/{deploymentId}" do
    operation :get do
      key :summary, 'Get deployment'
      key :description, 'Fetch a specific deployment.'
      key :tags, ['deployment']

      [:siteId, :deploymentId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kitemjson) do
          schema do
            key :'$ref', :Deployment
          end
        end

        key :description, 'The deployment item.'
      end

      response 404 do
        content :'text/plain'
        key :description, 'Deployment not found.'
      end
    end

    operation :delete do
      key :summary, 'Cancel deployment.'
      key :description, 'Cancel a deployment.'
      key :tags, ['deployment']

      [:siteId, :deploymentId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 204 do
        key :description, 'Deployment successfully canceled.'
        header :'Location' do
          key :description, 'Location of the new deployment resource'
          schema do
            key :type, :string
          end
        end
      end
    end
  end

  # Display the details of a deployment
  def show
    allow :get, :delete, :put; vary_on :accept
    expires_in 60.seconds

    item = find_item(params[:id])
    item.links = links_for_item(item)

    render_result(item)
  end

  # Delete a deployment. Client must be authenticated and must own the deployment.
  #
  # Delegates to the Kadeploy API.
  def destroy
    ensure_authenticated!
    dpl = find_item(params[:id])
    authorize!(dpl.user_uid)
    dpl.base_uri = api_path
    dpl.tls_options = tls_options_for(:out)
    dpl.user = @credentials[:cn]

    begin
      dpl.cancel! if dpl.can_cancel?
    rescue StandardError => e
      raise ServerError, "Cannot cancel deployment: #{e.message}"
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

  # Create a new Deployment. Client must be authenticated.
  #
  # Delegates the request to the Kadeploy API.
  def create
    ensure_authenticated!
    begin
      payload = deployment_params.to_h
      Rails.logger.debug "Creating deployment with #{payload} from #{params} (after permit)"

      dpl = Grid5000::Deployment.new(payload)
      dpl.user_uid = @credentials[:cn]
      dpl.site_uid = Rails.whoami
      dpl.user = @credentials[:cn]
      dpl.base_uri = api_path
      dpl.tls_options = tls_options_for(:out)

      Rails.logger.info "Received deployment = #{dpl.inspect}"
    rescue StandardError => e
      raise BadRequest, "The deployment you are trying to submit is not valid: #{e.message}"
    end
    unless dpl.valid?
      raise BadRequest, "The deployment you are trying to submit is not valid: #{dpl.errors.to_a.join('; ')}"
    end

    files_base_uri = uri_to(parent_path + '/files', :in, :absolute)
    dpl.transform_blobs_into_files!(Rails.tmp, files_base_uri)

    begin
      dpl.launch || raise(ServerError,
                          dpl.errors.full_messages.join('; ').to_s)
    rescue => e
      error_msg_prefix = 'Cannot launch deployment: '

      case e
      when Grid5000::Errors::Kadeploy::ServerError
        raise ServerError, error_msg_prefix + e.message
      when Grid5000::Errors::Kadeploy::BadRequest
        raise BadRequest, error_msg_prefix + e.message
      else
        raise ServerError, error_msg_prefix + e.message
      end
    end

    location_uri = uri_to(
      resource_path(dpl.uid),
      :in, :absolute
    )

    dpl.links = links_for_item(dpl)

    render_opts = {
      location: location_uri,
      status: 201
    }
    render_result(dpl, render_opts)
  end

  # If the deployment is in the "canceled", "error", or "terminated" state,
  # return the deployment from DB. Otherwise, fetches the deployment status
  # from the kadeploy-server, and update the <tt>result</tt> attribute if the
  # deployment has finished.
  def update
    dpl = find_item(params[:id])
    dpl.base_uri = api_path
    dpl.tls_options = tls_options_for(:out)
    dpl.user = 'root' # Ugly hack since no auth is needed for this method on theg5k API

    begin
      dpl.touch! if dpl.active?
    rescue StandardError => e
      raise ServerError, e.message
    end

    location_uri = uri_to(
      resource_path(dpl.uid),
      :in, :absolute
    )

    render  plain: '',
            head: :ok,
            location: location_uri,
            status: 204
  end

  protected

  def deployment_params
    params.permit(:environment, :arch, :version, :key,
                  :partition_label, :block_device, :reformat_tmp,
                  :disable_disk_partitioning, :disable_bootloader_install,
                  :reboot_classical_timeout, :reboot_kexec_timeout,
                  :ignore_nodes_deploying, :vlan, nodes: [])
  end

  def collection_path
    site_deployments_path(params[:site_id])
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

  def find_item(id)
    item = Grid5000::Deployment.find_by_uid(id)
    raise NotFound, "Couldn't find #{Grid5000::Deployment} with ID=#{id}" if item.nil?

    item
  end

  def api_path(path = '')
    uri_to(
      File.join(
        site_path(params[:site_id]),
        '/internal/kadeployapi/deployment',
        path
      ),
      :out
    )
  end
end
