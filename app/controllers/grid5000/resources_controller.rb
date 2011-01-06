module Grid5000
  class ResourcesController < ApplicationController
  
    # Return a collection of resources
    def index
      collection = EM::Synchrony.sync repository.async_find(
        collection_path, 
        :branch => params[:branch],
        :version => params[:version]
      )
      collection['links'] = links_for_collection(collection)
      collection['items'].each{|item|
        item['links'] = links_for_item(item)
      }
      respond_to do |format|
        format.json { render :json => collection }
      end
    end

    def show
      path = resource_path(params[:id])
      resource = EM::Synchrony.sync repository.async_find(
        path, 
        :branch => params[:branch],
        :version => params[:version]
      )
      raise NotFound, "Cannot find resource #{path}" if resource.nil?
      resource['links'] = links_for_item(resource)
      respond_to do |format|
        format.json { render :json => resource }
      end
    end
  
    protected
  
    # Must be overwritten by descendants
    def collection_path
      raise NotImplemented
    end
    
    def resource_path(id)
      File.join(collection_path, id)
    end
    
    def parent_path
      collection_path.gsub(/\/(.+)$/, "")
    end
    
    # Should be overwritten
    def links_for_item(item)
      links = []
      links.push({
        "rel" => "self",
        "type" => media_type(:json),
        "href" => uri_to(resource_path(item["uid"]))
      })
      links.push({
        "rel" => "parent",
        "type" => media_type(:json),
        "href" => uri_to(parent_path)
      }) unless parent_path.blank?
      links.push({
        "rel" => "versions",
        "type" => media_type(:json_collection),
        "href" => uri_to(File.join(resource_path(item["uid"]), "versions"))
      })
      links
    end
    
    # Should be overwritten
    def links_for_collection(collection)
      links = []
      links.push({
        "rel" => "self",
        "type" => media_type(:json_collection),
        "href" => uri_to(collection_path)
      })
      links.push({
        "rel" => "parent",
        "type" => media_type(:json),
        "href" => uri_to(parent_path)
      }) unless parent_path.blank?
      links
    end
    
  end
end # module Grid5000
