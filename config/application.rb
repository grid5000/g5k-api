require File.expand_path('../boot', __FILE__)

# Avoid loading all of rails with require 'rails/all':
require "active_record/railtie"
require "action_controller/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.

Bundler.require(:default, Rails.env) if defined?(Bundler)

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
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    require 'rack/pretty_json'
    config.middleware.use Rack::PrettyJSON, :warning => true
    config.middleware.use Rack::JSONP, :carriage_return => true

    config.generators do |g|
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end

    config.time_zone = 'UTC'

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    CONFIG = YAML.load_file(File.join(Rails.root, "config", "defaults.yml"))[Rails.env]
  end
end
