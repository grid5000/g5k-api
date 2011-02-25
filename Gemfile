source 'http://rubygems.org'

gem('rake', '~> 0.8.7')
gem('rails', '~> 3.0')
gem 'eventmachine', 
  # '~> 0.12', 
  # Due to a bug on Debian, we need to use the edge version (~>1.0)
  :git => 'git://github.com/eventmachine/eventmachine.git'
gem('rack-fiber_pool', '~> 0.9')
gem('em-synchrony', '~> 0.2')
gem('mysqlplus', '~> 0.1')
gem('em-mysqlplus', '~> 0.1')
gem('em-http-request', '~> 0.2')
gem('addressable', '~> 2.2')
gem('thin', '~> 1.2.7')
gem('state_machine', '~> 0.9')
gem 'grit'
gem 'syslogger'
gem 'haml'
gem 'rack-jsonp'

group :test, :development do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'autotest'
  gem 'autotest-growl'
  gem 'factory_girl_rails'
  gem 'rcov'
end


