require 'resources_controller'

class EnvironmentsController < ResourcesController

  protected
  
  def collection_path
    if params[:site_id]
      site_environments_path(params[:site_id])
    else
      environments_path
    end
  end
  
  def links_for_item(item)
    links = super(item)
    links
  end

end
