require 'resources_controller'

class NetworkEquipmentsController < ResourcesController

  protected

  def collection_path
    if params[:site_id]
      site_network_equipments_path(params[:site_id])
    else
      network_equipments_path
    end
  end

end
