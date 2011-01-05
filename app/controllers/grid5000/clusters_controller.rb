module Grid5000
  class ClustersController < ResourcesController
  
    protected
    
    def collection_path
      "/grid5000/#{params[:site_id]}/clusters"
    end
  
  end
end