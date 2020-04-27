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

ENV["RAILS_ENV"] ||= 'test'
ENV["RACK_ENV"] ||= ENV["RAILS_ENV"]

require 'simplecov'
SimpleCov.start 'rails'

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
    expect(response.headers['Content-Type']).to match case type
    when :json
      %r{application/json}
    when :txt
      %r{text/plain}
    when :json_collection
      %r{application/json}
    else
      raise MediaTypeError, "Media type #{type.inspect} was not expected."
    end
  end
end

module HeaderHelper
  class HeaderError < StandardError; end

  def assert_vary_on(*args)
    expect((response.headers['Vary'] || "").downcase.split(/\s*,\s*/).sort).to eq(args.map{|v| v.to_s.dasherize}.sort)
  end
  def assert_allow(*args)
    expect((response.headers['Allow'] || "").downcase.split(/\s*,\s*/).sort).to eq(args.map{|v| v.to_s.dasherize}.sort)
  end
  def assert_expires_in(seconds, options = {})
    values = (response.headers['Cache-Control'] || "").downcase.split(/\s*,\s*/)
    expect(values).to include("public") if options[:public]
    expect(values).to include("max-age=#{seconds}")
  end

  def authenticate_as(username)
    header = "HTTP_"+Rails.my_config(:header_user_cn).gsub("-","_").upcase
    @request.env[header] = username
  end
end

RSpec.configure do |config|

  config.infer_spec_type_from_file_location!
  config.include FactoryBot::Syntax::Methods
  config.before(:each) do
    @now = Time.now
    allow(Time).to receive(:now).and_return(@now)

    Grid5000::Deployment.delete_all
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

  config.around(:each) do |example|
    Rails.logger.debug example.metadata[:full_description]
    EM.synchrony do
      ActiveRecord::Base.connection_pool.with_connection do
        example.run
      end
      EM.stop
    end
  end

  # == Mock Framework
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  include MediaTypeHelper
  include HeaderHelper
  # FIXME: this is bad, this should be removed.
  include ApplicationHelper

end
