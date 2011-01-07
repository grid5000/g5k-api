class EnvironmentsController < ResourcesController

  protected
  
  def collection_path
    if params[:site_id]
      platform_site_environments_path(params[:platform_id], params[:site_id])
    else
      platform_environments_path(params[:platform_id])
    end
  end
  
  def links_for_item(item)
    links = super(item)
    links
  end

end
