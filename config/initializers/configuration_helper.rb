module ConfigurationHelper
  def my_config(key)
    Api::Application::CONFIG[key.to_sym] || Api::Application::CONFIG[key.to_s]
  end

  def tmp
    Rails.root.join(my_config(:tmp_path))
  end

  # Returns a string specific to the machine/cluster
  # where this server is hosted
  def whoami
    if Rails.env == "test"
      "rennes"
    else
      ENV['WHOAMI'] || `hostname`.split(".")[1]
    end
  end

end

Rails.extend ConfigurationHelper

Rails.logger.level = Logger.const_get(Rails.my_config(:logger_level) || "INFO")
