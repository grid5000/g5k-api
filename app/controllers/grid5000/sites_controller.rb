module Grid5000
  class SitesController < ResourcesController
  
    protected
    
    def collection_path
      "grid5000/sites"
    end
    
    def links_for_item(item)
      links = super(item)
      %w{clusters environments jobs deployments metrics status}.each do |rel|
        links.push({
          "rel" => rel,
          "type" => media_type(:json_collection),
          "href" => uri_to(File.join(resource_path(item["uid"]), rel))
        })
      end
      links
    end
  
  end
end