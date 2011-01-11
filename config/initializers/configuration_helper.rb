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
end

Rails.extend ConfigurationHelper
