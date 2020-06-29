source 'https://rubygems.org'

gem 'rake'
gem 'rails', '~> 6.0.2'
gem 'bootsnap', require: false
# jQuery is the default JavaScript library as from Rails 3.1
gem 'jquery-rails'

gem 'rack-fiber_pool', '~> 0.9'
gem "mysql2", '~> 0.5.3'
gem "ruby-mysql", :require => "mysql"
gem 'addressable', '~> 2.2'
gem 'thin', '~> 1.7.0'
gem 'state_machines-activerecord'
gem 'syslogger'
gem 'haml', '~> 5.1.2'
gem 'rack-jsonp'
gem 'pg'
gem 'nokogiri'
gem 'rugged'

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'erubis', '~> 2.7'

group :development do
  # for ruby scripts written to replicate
  # bugs
  gem 'ruby-cute'
  gem 'byebug'
end

group :test do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter', '~> 0.3.0' #for tests generated for Jenkins
  gem 'factory_bot_rails'
  gem 'simplecov'
  gem 'net-ssh', "< 5.0.0" #version as from 5.0.0 require ruby > 2.2.6
  gem 'net-ssh-multi'
  gem 'byebug'
end

