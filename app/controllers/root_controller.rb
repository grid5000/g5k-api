class RootController < ApplicationController
  # Display links to sub resources.
  def index
    root = {
      :uid => "grid5000",
      :links => [
        {
          :rel => "self",
          :href => uri_to(root_path)
        },
        {
          :rel => "environments",
          :href => uri_to(environments_path)
        },
        {
          :rel => "sites",
          :href => uri_to(sites_path)
        },
         {
          :rel => "users",
          :href => uri_to("/users")
         },
         {
           :rel => "notifications",
           :href => uri_to(notifications_path)
         }
      ]
    }
    respond_to do |format|
      format.g5kjson { render :json => root }
      format.json { render :json => root }
    end
  end
end
