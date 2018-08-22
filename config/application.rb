# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path('../boot', __FILE__)

# Avoid loading all of rails with require 'rails/all':
require "active_record/railtie"
require "action_controller/railtie"

if defined?(Bundler)
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups)
end

# Explicitly require libs when gem name is not sufficient
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-http'
require 'addressable/uri'
require 'rack/fiber_pool'
require 'rack/jsonp'
require 'rack/lint'

module Api

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # config.middleware.insert_before Rack::Runtime, Rack::FiberPool

    # Custom directories with classes and modules you want to be autoloadable.
    #config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += %W(#{config.root}/lib)

    require 'rack/pretty_json'
    config.middleware.insert_before Rack::Runtime, Rack::FiberPool, :size => 15
    config.middleware.use Rack::PrettyJSON, :warning => true
    config.middleware.use Rack::JSONP, :carriage_return => true
    # config.middleware.delete ActionDispatch::ShowExceptions

    config.generators do |g|
      g.fixture_replacement :factory_bot, :dir => "spec/factories"
    end

    config.time_zone = 'UTC'

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # 3.0.0 to 3.13 : add asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'

    CONFIG = YAML.load_file(File.join(Rails.root, "config", "defaults.yml"))[Rails.env]
  end
end
