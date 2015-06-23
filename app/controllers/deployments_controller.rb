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
  LIMIT = 50
  LIMIT_MAX = 500

  # List deployments
  def index
    allow :get, :post; vary_on :accept

    offset = [(params[:offset] || 0).to_i, 0].max
    limit = [(params[:limit] || LIMIT).to_i, LIMIT_MAX].min
    order = "DESC"
    order = "ASC" if params[:reverse] && params[:reverse].to_s == "true"

    items = Grid5000::Deployment.order("created_at #{order}")
    items = items.where(:user_uid => params[:user]) if params[:user]
    items = items.where(:status => params[:status]) if params[:status]

    total = items.count

    items = items.offset(offset).limit(limit)

    items.each{|item|
      item.links = links_for_item(item)
    }

    result = {
      "total" => total,
      "offset" => offset,
      "items" => items,
      "links" => links_for_collection
    }

    respond_to do |format|
      format.g5kcollectionjson { render :json => result }
      format.json { render :json => result }
    end
  end

  # Display the details of a deployment
  def show
    allow :get, :delete, :put; vary_on :accept
    expires_in 60.seconds

    item = find_item(params[:id])
    item.links = links_for_item(item)

    respond_to do |format|
      format.g5kitemjson { render :json => item }
      format.json { render :json => item }
    end
  end

  # Delete a deployment. Client must be authenticated and must own the deployment.
  #
  # Delegates to the Kadeploy API.
  def destroy
    ensure_authenticated!
    dpl = find_item(params[:id])
    authorize!(dpl.user_uid)
    dpl.base_uri = api_path()
    dpl.user = @credentials[:cn]

    begin
      dpl.cancel! if dpl.can_cancel?
    rescue Exception => e
      raise ServerError, "Cannot cancel deployment: #{e.message}"
    end

    location_uri = uri_to(
      resource_path(params[:id]),
      :in, :absolute
    )

    render  :text => "",
            :head => :ok,
            :location => location_uri,
            :status => 202
  end

  # Create a new Deployment. Client must be authenticated.
  #
  # Delegates the request to the Kadeploy API.
  def create
    ensure_authenticated!

    dpl = Grid5000::Deployment.new(payload)
    dpl.user_uid = @credentials[:cn]
    dpl.site_uid = Rails.whoami
    dpl.user = @credentials[:cn]
    dpl.base_uri = api_path()

    Rails.logger.info "Received deployment = #{dpl.inspect}"
    raise BadRequest, "The deployment you are trying to submit is not valid: #{dpl.errors.to_a.join("; ")}" unless dpl.valid?

    # WARN: this is a blocking call as it creates a file on disk.
    # we may want to defer it or implement it natively with EventMachine
    files_base_uri = uri_to(parent_path+"/files",:in, :absolute)
    dpl.transform_blobs_into_files!(Rails.tmp, files_base_uri)

    begin
      dpl.launch || raise(ServerError,
        "#{dpl.errors.full_messages.join("; ")}")
    rescue Exception => e
      raise ServerError, "Cannot launch deployment: #{e.message}"
    end

    location_uri = uri_to(
      resource_path(dpl.uid),
      :in, :absolute
    )

    dpl.links = links_for_item(dpl)

    render_opts = {
      #:methods => [:resources_by_type, :assigned_nodes],
      :location => location_uri,
      :status => 201
    }
    respond_to do |format|
      format.g5kitemjson { render render_opts.merge(:json => dpl) }
      format.json { render render_opts.merge(:json => dpl) }
    end
  end

  # If the deployment is in the "canceled", "error", or "terminated" state,
  # return the deployment from DB. Otherwise, fetches the deployment status
  # from the kadeploy-server, and update the <tt>result</tt> attribute if the
  # deployment has finished.
  def update
    dpl = find_item(params[:id])
    dpl.base_uri = api_path()
    dpl.user = 'root' # Ugly hack since no auth is needed for this method on theg5k API

    begin
      dpl.touch! if dpl.active?
    rescue Exception => e
      raise ServerError, e.message
    end

    location_uri = uri_to(
      resource_path(dpl.uid),
      :in, :absolute
    )

    render  :text => "",
            :head => :ok,
            :location => location_uri,
            :status => 204
  end

  protected

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
        "rel" => "self",
        "href" => uri_to(resource_path(item['uid'])),
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

  def find_item(id)
    item = Grid5000::Deployment.find_by_uid(id)
    raise NotFound, "Couldn't find #{Grid5000::Deployment} with ID=#{id}" if item.nil?
    item
  end

  def api_path(path='')
    uri_to(
      File.join(
        site_path(params[:site_id]),
        "/internal/kadeployapi/deployment",
        path
      ),
      :out
    )
  end

  # Not useful atm
=begin
  def wrap_item(item,params,orig=false)
    ret = item
    item = item.dup
    ret.clear
    ret['orig'] = item if orig

    ret['uid'] = item['wid'] || item['id']
    ret['site_uid'] = params[:site_id]
    ret['user_uid'] = item['user']
    #item['created_at'] = item['start_time']
    if item['nodes'].is_a?(Hash)
      nodes = item['nodes']
      ret['nodes'] = []
      ret['result'] = {}
      nodes['ok'].each do |node|
        ret['nodes'] << node
        ret['result'][node] = { 'state' => 'OK' }
      end
      nodes['processing'].each do |node|
        ret['nodes'] << node
        ret['result'][node] = { 'state' => 'OK' }
      end
      nodes['ko'].each do |node|
        ret['nodes'] << node
        ret['result'][node] = { 'state' => 'KO' }
      end
    else
      ret['nodes'] = item['nodes']
    end

    if item['error']
      ret['status'] = :error
    elsif item['done']
      ret['status'] = :terminated
    else
      ret['status'] = :processing
    end

    ret['links'] = links_for_item(ret)

    ret
  end
=end
end
