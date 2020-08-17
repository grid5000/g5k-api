require 'resources_controller'

class GlobalController < ResourcesController
  def index
    allow :get

    fetch('/')
  end

  def show_site
    allow :get

    fetch("/sites/#{params[:site_id]}")
  end

  def show_job
    allow :get

    fetch("/sites/#{params[:site_id]}")
  end

  protected

  def collection_path
    global_path
  end

  def links_for_collection
    [
      {
        "rel" => "self",
        "href" => uri_to(collection_path),
        "type" => api_media_type(:g5kcollectionjson)
      },
      {
        "rel" => "parent",
        "href" => uri_to(parent_path),
        "type" => api_media_type(:g5kitemjson)
      }
    ]
  end
end
