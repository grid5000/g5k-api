# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'webmock/rspec'

Grit.debug = true

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

def fixture(filename)
  File.read(File.join(File.dirname(__FILE__), "fixtures", filename))
end

# def authenticate_as(username)
#   @request.env['HTTP_X_BONFIRE_ASSERTED_ID'] = username
# end


def json
  @json ||= JSON.parse(response.body)
end

RSpec.configure do |config|
  include ConfigurationHelper
  
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
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  
end
