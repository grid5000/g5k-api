class JobsController < ApplicationController
  DEFAULT_LIMIT = 100
  MAX_LIMIT = 1000
  
  def index
    allow :get, :post; vary_on :accept
    jobs = OAR::Job.expanded.order("job_id DESC")
    total = jobs.count
    offset = (params[:offset] || 0).to_i
    limit = [(params[:limit] || DEFAULT_LIMIT).to_i, MAX_LIMIT].min
    jobs = jobs.offset(offset).limit(limit)
    jobs = jobs.where(:job_user => params[:user]) if params[:user]  
    jobs = jobs.where(:state => params[:state].capitalize) unless params[:state].blank?
    jobs = jobs.where(:queue_name => params[:queue]) if params[:queue]
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
      format.json { render :json => result }
    end
  end
  
  def show
    allow :get, :delete; vary_on :accept
    job = OAR::Job.expanded.find(params[:id])
    job.links = links_for_item(job)
    respond_to do |format|
      format.json { render :json => job }
    end
  end
  
  def destroy
    # forward to OAR API
  end
  
  def create
    # forward to OAR API
  end
  
  protected
  def collection_path
    platform_site_jobs_path(params[:platform_id], params[:site_id])
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
