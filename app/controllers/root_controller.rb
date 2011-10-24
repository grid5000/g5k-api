class RootController < ApplicationController
  # Display links to sub resources.
  def index
    root = {
      :uid => "grid5000",
      :links => [
        {
          :rel => "self",
          :href => uri_to(root_path),
          :type => media_type(params[:format])
        },
        {
          :rel => "environments",
          :href => uri_to(environments_path),
          :type => media_type(params[:format])
        },
        {
          :rel => "sites",
          :href => uri_to(sites_path),
          :type => media_type(params[:format])
        }
      ]
    }
    respond_to do |format|
      format.g5kjson { render :json => root }
      format.json { render :json => root }
    end
  end
end
