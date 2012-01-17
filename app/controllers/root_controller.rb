class RootController < ResourcesController
  # Display links to sub resources.
    # 
    # def show
    #   root = {
    #     :uid => "grid5000",
    #     :version => Grid5000::VERSION,
    #     :timestamp => Time.now.to_i,
    #     :links => [
    #       {
    #         :rel => "self",
    #         :href => uri_to(root_path)
    #       },
    #       {
    #         :rel => "environments",
    #         :href => uri_to(environments_path)
    #       },
    #       {
    #         :rel => "sites",
    #         :href => uri_to(sites_path)
    #       },
    #        {
    #         :rel => "users",
    #         :href => uri_to("/users")
    #        },
    #        {
    #          :rel => "notifications",
    #          :href => uri_to(notifications_path)
    #        }
    #     ]
    #   }
    #   respond_to do |format|
    #     format.g5kitemjson { render :json => root }
    #     format.json { render :json => root }
    #   end
    # end
    
  protected

  def collection_path
    "/"
  end
  
  def resource_path(id)
    ""
  end

  def links_for_item(item)
    links = super(item)
    item['release'] = Grid5000::VERSION
    item['timestamp'] = Time.now.to_i
    %w{users notifications}.each do |rel|
      links.push({
        "rel" => rel,
        "type" => media_type(:g5kcollectionjson),
        "href" => uri_to(File.join(resource_path(item["uid"]), rel))
      })
    end
    links
  end
end
