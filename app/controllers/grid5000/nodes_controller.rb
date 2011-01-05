module Grid5000
  class NodesController < ResourcesController
  
    protected
    
    def collection_path
      "grid5000/sites/#{params[:site_id]}" +
      "/clusters/#{params[:cluster_id]}/nodes"
    end
    
    def links_for_item(item)
      links = super(item)
      links
    end
  
  end
end