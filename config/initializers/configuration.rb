puts "Looking for defaults configuration file in #{BrokerApi::Application::BONFIRE_API_DEFAULTS_CONFIG_PATHS.inspect}..."
config_file = BrokerApi::Application::BONFIRE_API_DEFAULTS_CONFIG_PATHS.find { |path|
  fullpath = File.expand_path(path)
  File.exist?(fullpath) && File.readable?(fullpath)
}
puts "=> Using defaults configuration file located at: #{config_file}"

APP_CONFIG = YAML.load_file(config_file)[Rails.env]

module ConfigurationHelper
  def default_xml_namespace
    APP_CONFIG['default_xml_namespace']
  end
  
  def default_media_type
    APP_CONFIG['default_media_type']
  end
  
  def header_user_cn
    APP_CONFIG['header_user_cn']
  end
  
  def enactor_uri(*path)
    if path.empty?
      APP_CONFIG['enactor_uri']
    else
      "#{APP_CONFIG['enactor_uri']}#{path.join("/")}"
    end
  end
end

ActiveRecord::Base.extend(ConfigurationHelper)

