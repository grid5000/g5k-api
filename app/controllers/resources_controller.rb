class ResourcesController < ApplicationController

  MAX_AGE = 60.seconds

  # Return a collection of resources
  def index
    fetch(collection_path)
  end

  def show
    fetch(resource_path(params[:id]))
  end

  protected
  def fetch(path)
    allow :get; vary_on :accept
    Rails.logger.info "Fetching #{path}"
    Rails.logger.info "Repository=#{repository.inspect}"

    branch = params[:branch] || 'master'
    branch = ['origin', branch].join("/") unless Rails.env == "test"

    object = EM::Synchrony.sync repository.async_find(
      path.gsub(/\/?platforms/,''),
      :branch => branch,
      :version => params[:version]
    )

    raise NotFound, "Cannot find resource #{path}" if object.nil?
    if object.has_key?('items')
      object['links'] = links_for_collection(object)
      object['items'].each{|item|
        item['links'] = links_for_item(item)
      }
    else
      object['links'] = links_for_item(object)
    end

    object["version"] = repository.commit.id

    last_modified [repository.commit.committed_date, File.mtime(__FILE__)].max
    
    # If client asked for a specific version, it won't change anytime soon
    if params[:version] && params[:version] == object["version"]
      expires_in(
        24*3600*30,
        :public => true
      )
    else
      expires_in(
        MAX_AGE, 
        :public => true, 
        'must-revalidate' => true, 
        'proxy-revalidate' => true, 
        's-maxage' => MAX_AGE
      )
    end
    etag object.hash

    respond_to do |format|
      format.json { render :json => object }
    end
  end

  # Must be overwritten by descendants
  def collection_path
    raise NotImplemented
  end

  def resource_path(id)
    File.join(collection_path, id)
  end

  def parent_path
    collection_path.gsub(/\/[^\/]+$/, "")
  end

  # Should be overwritten
  def links_for_item(item)
    links = []
    links.push({
      "rel" => "self",
      "type" => media_type(:json),
      "href" => uri_to(resource_path(item["uid"]))
    })
    links.push({
      "rel" => "parent",
      "type" => media_type(:json),
      "href" => uri_to(parent_path)
    })
    links.push({
      "rel" => "version",
      "type" => media_type(:json),
      "href" => uri_to(File.join(resource_path(item["uid"]), "versions", item["version"]))
    })
    links.push({
      "rel" => "versions",
      "type" => media_type(:json_collection),
      "href" => uri_to(File.join(resource_path(item["uid"]), "versions"))
    })
    links
  end

  # Should be overwritten
  def links_for_collection(collection)
    links = []
    links.push({
      "rel" => "self",
      "type" => media_type(:json_collection),
      "href" => uri_to(collection_path)
    })
    links.push({
      "rel" => "parent",
      "type" => media_type(:json),
      "href" => uri_to(parent_path)
    }) unless parent_path.blank?
    links
  end

end
