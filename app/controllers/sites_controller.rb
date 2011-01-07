class SitesController < ResourcesController

  def status
    # fetch valid clusters
    url = uri_to(
      platform_site_clusters_path(params[:platform_id], params[:id]),
      :out
    )
    http = EM::HttpRequest.new(url).get(
      :timeout => 5,
      :head    => {'Accept' => media_type(:json_collection)}
    )
    continue_if!(http, :is => [200])
    valid_clusters = JSON.parse(http.response)['items'].map{|i| i['uid']}
    result = {
      "uid" => Time.now.to_i,
      "nodes" => OAR::Resource.status(:clusters => valid_clusters),
      "links" => [
        {
          "rel" => "self",
          "href" => uri_to(status_platform_site_path(
            params[:platform_id], params[:id]
          )),
          "type" => media_type(:json)
        },
        {
          "rel" => "parent",
          "href" => uri_to(platform_site_path(
            params[:platform_id], params[:id]
          )),
          "type" => media_type(:json)
        }
      ]
    }
    respond_to do |format|
      format.json {
        render :json => result
      }
    end
  end
  
  protected
  
  def collection_path
    platform_sites_path(params[:platform_id])
  end
  
  def links_for_item(item)
    links = super(item)
    %w{clusters environments jobs deployments metrics status}.each do |rel|
      links.push({
        "rel" => rel,
        "type" => media_type(:json_collection),
        "href" => uri_to(File.join(resource_path(item["uid"]), rel))
      })
    end
    links
  end

end
