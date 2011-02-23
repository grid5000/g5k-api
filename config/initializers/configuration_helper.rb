puts "Looking for defaults configuration file in #{Api::Application::DEFAULTS_CONFIG_PATHS.inspect}..."
config_file = Api::Application::DEFAULTS_CONFIG_PATHS.find { |path|
  fullpath = File.expand_path(path)
  File.exist?(fullpath) && File.readable?(fullpath)
}
puts "=> Using defaults configuration file located at: #{config_file}"

require 'yaml'
YAML::ENGINE.yamler = "syck"

APP_CONFIG = YAML.load_file(config_file)[Rails.env]

module ConfigurationHelper
  def my_config(key)
    APP_CONFIG[key.to_sym] || APP_CONFIG[key.to_s]
  end

  def tmp
    Rails.root.join(my_config(:tmp_path))
  end

  # Returns a string specific to the machine/cluster
  # where this server is hosted
  def whoami
    ENV['WHOAMI'] || `hostname`.split(".")[1]
  end

end

Rails.extend ConfigurationHelper

Rails.logger.level = Logger.const_get(Rails.my_config(:logger_level) || "INFO")
