require 'resources_controller'

class ClustersController < ResourcesController

  protected
  
  def collection_path
    site_clusters_path(params[:site_id])
  end

end
