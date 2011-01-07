class ClustersController < ResourcesController

  protected
  
  def collection_path
    platform_site_clusters_path(params[:platform_id], params[:site_id])
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
