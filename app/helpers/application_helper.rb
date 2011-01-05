module ApplicationHelper
  
  include ConfigurationHelper
  
  def link_attributes_for(attributes = {})
    attributes[:type] ||= default_media_type
    attributes
  end
end
