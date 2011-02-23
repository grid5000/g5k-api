require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.

Bundler.require(:default, Rails.env) if defined?(Bundler)

# Explicitly require libs when gem name is not sufficient
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-activerecord'
require 'em-http'
require 'addressable/uri'
require 'rack/fiber_pool'
require 'rack/jsonp'
require 'rack/lint'

module Api

  class Application < Rails::Application

    DATABASE_CONFIG_PATHS = [
      ENV['G5KAPI_DATABASE_CONFIG'],
      "~/.g5kapi/database.yml",
      "/etc/g5kapi/database.yml",
      Rails.root.join("config/options/database.yml").to_path
    ].compact

    DEFAULTS_CONFIG_PATHS = [
      ENV['G5KAPI_DEFAULTS_CONFIG'],
      "~/.g5kapi/defaults.yml",
      "/etc/g5kapi/defaults.yml",
      Rails.root.join("config/options/defaults.yml").to_path
    ].compact

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # config.middleware.insert_before Rack::Runtime, Rack::FiberPool

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    require 'rack/pretty_json'
    config.middleware.use Rack::PrettyJSON, :warning => true
    config.middleware.use Rack::JSONP, :carriage_return => true

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :garbage_collector

    config.generators do |g|
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w()

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    puts "Looking for database configuration file in #{DATABASE_CONFIG_PATHS.inspect}..."
    found = DATABASE_CONFIG_PATHS.find { |path|
      fullpath = File.expand_path(path)
      File.exist?(fullpath) && File.readable?(fullpath)
    }
    if found.nil?
      fail "=> Cannot find an existing and readable file in #{DATABASE_CONFIG_PATHS.inspect}"
    else
      paths.config.database = found
      puts "=> Using database configuration file located at: #{paths.config.database.paths[0]}"
    end
  end
end
