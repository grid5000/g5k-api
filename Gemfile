source 'http://rubygems.org'
source 'http://g5k-campaign.gforge.inria.fr/pkg'

gem 'rake', '>= 0.8.7'
gem 'rails', '~> 3.0.0'
gem 'eventmachine',
  # '~> 0.12',
  # Due to a bug on Debian, we need to use the edge version (~>1.0)
  :git => 'https://github.com/eventmachine/eventmachine.git'
gem 'rack-fiber_pool', '~> 0.9'
gem 'em-synchrony', '~> 0.2'
gem 'em-http-request', '~> 0.2'
gem "mysql2", "~>0.2.0"
gem "ruby-mysql", :require => "mysql"
gem 'addressable', '~> 2.2'
gem 'thin', '~> 1.2.7'
gem 'state_machine', '~> 0.9'
gem 'grit'
gem 'syslogger'
gem 'haml'
gem 'rack-jsonp'

gem 'blather',
  :git => 'https://github.com/sprsquish/blather.git',
  :tag => 'develop'

group :test, :development do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'autotest'
  gem 'autotest-growl'
  gem 'factory_girl_rails'
  gem 'rcov'
  gem 'capistrano'
  gem 'g5k-campaign', '~> 0.9.2'
end


