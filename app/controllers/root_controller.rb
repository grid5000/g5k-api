class RootController < ApplicationController
  # Display links to sub resources.
  def index
    respond_to do |format|
      format.json {
        render :json => {
          :uid => "grid5000",
          :links => [
            {
              :rel => "self",
              :href => uri_to(root_path),
              :type => media_type(:json)
            },
            {
              :rel => "environments",
              :href => uri_to(environments_path),
              :type => media_type(:json_collection)
            },
            {
              :rel => "sites",
              :href => uri_to(sites_path),
              :type => media_type(:json_collection)
            }
          ]
        }
      }
    end
  end
end
