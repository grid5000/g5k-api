require 'resources_controller'

class ClustersController < ResourcesController

  protected
  
  def collection_path
    site_clusters_path(params[:site_id])
  end
  
  def links_for_item(item)
    links = super(item)
    links.push({
      "rel" => "nodes",
      "type" => media_type(:g5kcollectionjson),
      "href" => uri_to(File.join(resource_path(item["uid"]), "nodes"))
    })
    links
  end

end
