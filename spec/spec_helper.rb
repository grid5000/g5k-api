# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'webmock/rspec'

Grit.debug = false

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

def fixture(filename)
  File.read(File.join(File.dirname(__FILE__), "fixtures", filename))
end

def json
  @json ||= JSON.parse(response.body)
end

module MediaTypeHelper
  class MediaTypeError < StandardError; end
  
  def assert_media_type(type)
    response.headers['Content-Type'].should =~ case type
    when :json
      %r{application/json}
    when :txt
      %r{text/plain}
    when :json_collection
      %r{application/collection+json}
    else
      raise MediaTypeError, "Media type #{type.inspect} was not expected."
    end
  end
end

module HeaderHelper
  class HeaderError < StandardError; end
  
  def assert_vary_on(*args)
    (response.headers['Vary'] || "").downcase.split(/\s*,\s*/).sort.should == args.map{|v| v.to_s.dasherize}.sort
  end
  def assert_allow(*args)
    (response.headers['Allow'] || "").downcase.split(/\s*,\s*/).sort.should == args.map{|v| v.to_s.dasherize}.sort
  end
  def assert_expires_in(seconds, options = {})
    values = (response.headers['Cache-Control'] || "").downcase.split(/\s*,\s*/)
    values.should include("public") if options[:public]
    values.should include("max-age=#{seconds}")
  end
end

RSpec.configure do |config|
  include ConfigurationHelper
  include MediaTypeHelper
  include HeaderHelper
  
  config.before(:each) do
    @json = nil
  end
  
  config.before(:all) do
    @repository_path_prefix = "data"
    # INIT TESTING GIT REPOSITORY
    @repository_path = File.expand_path(
      '../fixtures/reference-repository',
      __FILE__
    )
    if File.exist?( File.join(@repository_path, 'git.rename') )
      cmd = "mv #{File.join(@repository_path, 'git.rename')} #{File.join(@repository_path, '.git')}"
      system cmd
    end
  end
  
  config.after(:all) do
    if File.exist?( File.join(@repository_path, '.git') )
      system "mv #{File.join(@repository_path, '.git')} #{File.join(@repository_path, 'git.rename')}"
    end
  end

  # == Mock Framework
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  
end
