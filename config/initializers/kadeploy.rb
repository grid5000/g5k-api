ENV['KADEPLOY_CONFIG_DIR'] = "none"

require 'kadeploy'

Kadeploy.config = Rails.my_config(:kadeploy_uri)
Kadeploy.logger = Rails.logger
