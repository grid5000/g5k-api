require 'resources_controller'

class NodesController < ResourcesController

  protected

  def collection_path
    site_cluster_nodes_path(params[:site_id], params[:cluster_id])
  end

end
