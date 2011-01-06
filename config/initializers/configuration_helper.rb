puts "Looking for defaults configuration file in #{Api::Application::DEFAULTS_CONFIG_PATHS.inspect}..."
config_file = Api::Application::DEFAULTS_CONFIG_PATHS.find { |path|
  fullpath = File.expand_path(path)
  File.exist?(fullpath) && File.readable?(fullpath)
}
puts "=> Using defaults configuration file located at: #{config_file}"

APP_CONFIG = YAML.load_file(config_file)[Rails.env]

module ConfigurationHelper
  def my_config(key)
    APP_CONFIG[key.to_sym] || APP_CONFIG[key.to_s]
  end
  
  def uri_to(path, relative=true)
    uri = File.join(*["/", request.env['HTTP_X_API_VERSION'], path].compact)
    uri = URI.join(base_uri, uri).to_s unless relative
    uri
  end
  
  def base_uri
    my_config(:base_uri)
  end
  
  def repository
    @repository ||= Grid5000::Repository.new(
      File.expand_path(
        my_config(:reference_repository_path),
        Rails.root
      ), 
      my_config(:reference_repository_path_prefix)
    )
  end
  
  def media_type(type)
    case type
    when :json
      "application/json"
    when :json_collection
      "application/collection+json"
    end
  end
end


