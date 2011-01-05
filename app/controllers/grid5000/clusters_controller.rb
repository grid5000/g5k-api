module Grid5000
  class ClustersController < ResourcesController
  
    protected
    
    def collection_path
      "grid5000/sites/#{params[:site_id]}/clusters"
    end
    
    def links_for_item(item)
      links = super(item)
      links.push({
        "rel" => "nodes",
        "type" => media_type(:json_collection),
        "href" => uri_to(File.join(resource_path(item["uid"]), "nodes"))
      })
      links
    end
  
  end
end