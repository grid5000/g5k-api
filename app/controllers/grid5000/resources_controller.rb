module Grid5000
  class ResourcesController < ApplicationController
  
    # Return a collection of resources
    def index
      collection = EM::Synchrony.sync Resource.async_find(
        collection_path, 
        :in => repository, 
        :branch => params[:branch],
        :version => params[:version]
      )
      collection['links'] = links_for_collection(collection)
      collection['items'].each{|item|
        item['links'] = links_for_item(item)
      }
      respond_to do |format|
        format.json { render :json => resource }
      end
    end

    def show
      resource_path = "#{collection_path}/#{params[:id]}"
      resource = EM::Synchrony.sync Resource.find(
        resource_path, 
        :in => repository,
        :branch => params[:branch],
        :version => params[:version]
      )
      raise NotFound, "Cannot find resource #{resource_path}" if resource.nil?
      resource['links'] = links_for_item(resource)
      respond_to do |format|
        format.json { render :json => resource }
      end
    end
  
    protected
  
    def collection_path
      raise NotImplemented
    end
    
    def repository
      @repository ||= Grid5000::Repository.new(
        reference_repository_path, 
        reference_repository_path_prefix
      )
    end
    
    # Should be overwritten
    def links_for_item(item)
      []
    end
  
    def links_for_collection
  
    end
    
  end
end # module Grid5000
