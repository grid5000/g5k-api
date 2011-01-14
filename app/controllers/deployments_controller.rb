class DeploymentsController < ApplicationController
  LIMIT = 50
  LIMIT_MAX = 500
  
  # List deployments from DB
  def index
    allow :get, :post; vary_on :accept
    
    offset = [(params[:offset] || 0).to_i, 0].max
    limit = [(params[:limit] || LIMIT), LIMIT_MAX].min
    order = "DESC"
    order = "ASC" if params[:reverse] && params[:reverse].to_s == "true"
    
    items = Deployment.order("created_at #{order}")
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
      format.json { render :json => result }
    end
        
  end
  
  # Show deployments from DB
  def show
    allow :get, :delete, :put; vary_on :accept
    expires_in 60.seconds
    
    item = Deployment.find(params[:id])
    item.links = links_for_item(item)
    
    respond_to do |format|
      format.json { render :json => item }
    end
  end
  
  # Cancel deployment by contacting the kadeploy-server
  # Execution is made in a deferrable.
  def destroy
    ensure_authenticated!
    deployment = Deployment.find(params[:id])
    authorize!(deployment.user_uid)
    
    if deployment.active?
      kserver = Kadeploy::Server.new
      ok = EM::Synchrony.sync kserver.async_cancel!(params[:id])
      
      raise kserver.exception unless kserver.exception.nil?
      
      if ok
        deployment.cancel!
      else
        deployment.output = "Cannot cancel deployment"
        deployment.fail!
      end
    end
    
    location_uri = uri_to(
      resource_path(deployment.uid),
      :in, :absolute
    )
    
    render  :text => "",
            :head => :ok,
            :status => 204,
            :location => location_uri
  end
  
  # Receives deployment options, and contact the kadeploy-server to
  # launch the deployment.
  # 
  # If a key string is passed, it will be stored as a file in public/files
  # and the URI to the file will be passed to the kadeploy server.
  def create
    ensure_authenticated!

    deployment = Deployment.new(payload)
    deployment.user_uid = @credentials[:cn]
    deployment.site_uid = Rails.whoami
    
    if deployment.valid?
      
      files_base_uri = uri_to(
        parent_path+"/files",
        :in, :absolute
      )
      
      # FIXME: this is a blocking call as it creates a file on disk. 
      # we may want to defer it or implement it natively with EventMachine
      deployment.transform_blobs_into_files!(Rails.tmp, files_base_uri)
      
      kserver = Kadeploy::Server.new
      deployment.uid = EM::Synchrony.sync(
        kserver.async_submit!(deployment.to_a, :user => deployment.user_uid)
      )
      
      raise kserver.exception unless kserver.exception.nil?
      
      deployment.save!
      
      location_uri = uri_to(
        resource_path(deployment.uid),
        :in, :absolute
      )
      
      render  :text => "", 
              :head => :ok, 
              :location => location_uri, 
              :status => 201
      
    else
      raise BadRequest, "The deployment you are trying to submit is not valid: #{deployment.errors.full_messages.join("; ")}"
    end
  end
  
  # If the deployment is in the "canceled", "error", or "terminated" state, return the deployment from DB
  # Otherwise, fetches the deployment status from the kadeploy-server, and update the <tt>result</tt> attribute if the deployment has finished.
  def update
    deployment = Deployment.find(params[:id])
    
    if deployment.active?
      kserver = Kadeploy::Server.new
      status, result, output = EM::Synchrony.sync(
        kserver.async_touch!(params[:id])
      )
      
      raise kserver.exception unless kserver.exception.nil?
      
      deployment.result = result
      deployment.output = output
      
      case status
      when :terminated
        deployment.terminate!
      when :processing
        deployment.process!
      when :canceled
        deployment.cancel!
      else
        deployment.fail!
      end
    end
    
    location_uri = uri_to(
      resource_path(deployment.uid),
      :in, :absolute
    )
    
    render  :text => "", 
            :head => :ok, 
            :location => location_uri, 
            :status => 204
            
  end
  
  protected
  
  def collection_path
    platform_site_deployments_path(params[:platform_id], params[:site_id])
  end
  
  def parent_path
    platform_site_path(params[:platform_id], params[:site_id])
  end
  
  def resource_path(id)
    File.join(collection_path, id.to_s)
  end
  
  def links_for_item(item)
    [
      {
        "rel" => "self",
        "href" => uri_to(resource_path(item.uid)),
        "type" => media_type(:json)
      },
      {
        "rel" => "parent",
        "href" => uri_to(parent_path),
        "type" => media_type(:json)
      }      
    ]
  end
  
  def links_for_collection
    [
      {
        "rel" => "self",
        "href" => uri_to(collection_path),
        "type" => media_type(:json_collection)
      },
      {
        "rel" => "parent",
        "href" => uri_to(parent_path),
        "type" => media_type(:json)
      }      
    ]
  end
   
end