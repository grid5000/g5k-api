require 'grid5000/repository'
require 'grid5000/router'

module ApplicationHelper
  
  def link_attributes_for(attributes = {})
    attributes[:type] ||= default_media_type
    attributes
  end
  
  def uri_to(path, in_or_out = :in, relative_or_absolute = :relative)
    Grid5000::Router.uri_to(request, path, in_or_out, relative_or_absolute)
  end

  def repository
    @repository ||= Grid5000::Repository.new(
      File.expand_path(
        Rails.my_config(:reference_repository_path),
        Rails.root
      ), 
      Rails.my_config(:reference_repository_path_prefix),
      Rails.logger
    )
  end

  def media_type(type)
    t = Mime::Type.lookup_by_extension(type)
    if t
      t.to_s
    end
  end

end
