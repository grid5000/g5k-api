require 'resources_controller'

class PdusController < ResourcesController

  protected
  def collection_path
    site_pdus_path(params[:site_id])
  end

end
