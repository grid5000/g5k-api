module Grid5000
  class EnvironmentsController < ResourcesController
  
    protected
    
    def collection_path
      if params[:site_id]
        "grid5000/sites/#{params[:site_id]}/environments"
      else
        "grid5000/environments"
      end
    end
    
    def links_for_item(item)
      links = super(item)
      links
    end
  
  end
end