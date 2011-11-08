require 'resources_controller'

class SitesController < ResourcesController

  def status
    # fetch valid clusters
    url = uri_to(
      site_clusters_path(params[:id]),
      :out
    )
    http = EM::HttpRequest.new(url).get(
      :query   => {'branch' => params[:branch] || 'master'},
      :timeout => 5,
      :head    => {'Accept' => media_type(:json)}
    )
    continue_if!(http, :is => [200])
    valid_clusters = JSON.parse(http.response)['items'].map{|i| i['uid']}
    result = {
      "uid" => Time.now.to_i,
      "nodes" => OAR::Resource.status(:clusters => valid_clusters),
      "links" => [
        {
          "rel" => "self",
          "href" => uri_to(status_site_path(params[:id])),
          "type" => media_type(params[:format])
        },
        {
          "rel" => "parent",
          "href" => uri_to(site_path(params[:id])),
          "type" => media_type(params[:format])
        }
      ]
    }
    respond_to do |format|
      format.g5kitemjson { render :json => result }
      format.json { render :json => result }
    end
  end
  
  protected
  
  def collection_path
    sites_path
  end
  
  def links_for_item(item)
    links = super(item)
    %w{clusters environments jobs deployments metrics status}.each do |rel|
      links.push({
        "rel" => rel,
        "type" => media_type(:g5kcollectionjson),
        "href" => uri_to(File.join(resource_path(item["uid"]), rel))
      })
    end
    links
  end

end
