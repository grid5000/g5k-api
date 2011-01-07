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
  
  def uri_to(path, in_or_out = :in, relative_or_absolute = :relative)
    path_prefix = if request.env['HTTP_X_API_PATH_PREFIX'].blank?
      nil
    else
      File.join("/", (request.env['HTTP_X_API_PATH_PREFIX'] || ""))
    end
    mount_path = if request.env['HTTP_X_API_MOUNT_PATH'].blank?
      nil
    else
      File.join("/", (request.env['HTTP_X_API_MOUNT_PATH'] || ""))
    end
    uri = File.join("/", *[path_prefix, path].compact)
    uri.gsub!(mount_path, '') unless mount_path.nil?
    uri = "/" if uri.blank?
    if in_or_out == :out || relative_or_absolute == :absolute
      uri = URI.join(base_uri(in_or_out), uri).to_s
    end
    uri
  end
  
  def base_uri(in_or_out = :in)
    my_config("base_uri_#{in_or_out}".to_sym)
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
      "application/json"
    end
  end
end

ActiveRecord::Base.extend(ConfigurationHelper)

