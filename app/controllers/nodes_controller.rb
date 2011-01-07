class NodesController < ResourcesController

  protected
  
  def collection_path
    
    platform_site_cluster_nodes_path(params[:platform_id], params[:site_id], params[:cluster_id])
  end
  
  def links_for_item(item)
    links = super(item)
    links
  end

end
