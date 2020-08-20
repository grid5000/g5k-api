source 'https://rubygems.org'

gem 'bootsnap', require: false
gem 'rails', '~> 6.0.2'
gem 'rake'
# jQuery is the default JavaScript library as from Rails 3.1
gem 'jquery-rails'

gem 'addressable', '~> 2.2'
gem 'haml', '~> 5.1.2'
gem 'mysql2', '~> 0.5.3'
gem 'nokogiri'
gem 'pg'
gem 'rack-fiber_pool', '~> 0.9'
gem 'rack-jsonp'
gem 'ruby-mysql', require: 'mysql'
gem 'rugged'
gem 'state_machines-activerecord'
gem 'syslogger'
gem 'thin', '~> 1.7.0'

gem 'coffee-rails'
gem 'erubis', '~> 2.7'
gem 'sass-rails'
gem 'uglifier'

group :development do
  # for ruby scripts written to replicate
  # bugs
  gem 'ruby-cute'
end

group :test do
  gem 'factory_bot_rails'
  gem 'net-ssh', '< 5.0.0' # version as from 5.0.0 require ruby > 2.2.6
  gem 'net-ssh-multi'
  gem 'rspec'
  gem 'rspec_junit_formatter', '~> 0.3.0' # for tests generated for Jenkins
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'webmock'
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop'
  gem 'rubocop-rails'
end
