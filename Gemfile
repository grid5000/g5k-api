source 'https://rubygems.org'

gem 'rake'
gem 'rails', '~> 4.2.10'
# jQuery is the default JavaScript library as from Rails 3.1
gem 'jquery-rails'

gem 'eventmachine'
gem 'rack-fiber_pool', '~> 0.9'
gem 'em-synchrony'
gem 'em-http-request'
gem "mysql2", '~> 0.3.6'
gem "ruby-mysql", :require => "mysql"
gem 'addressable', '~> 2.2'
gem 'thin', '~> 1.5.0'
gem 'state_machines-activerecord'
gem 'gitlab-grit', :require => ['grit']
gem 'syslogger'
gem 'haml', '~> 4.0.4'
gem 'rack-jsonp'
gem 'pg', '< 1.0.0'
gem 'em-postgresql-adapter', :git => 'https://github.com/grid5000/em-postgresql-adapter.git'
gem 'nokogiri'
#gem 'nokogiri', '~> 1.5.6' #oldest version that blather handles

gem 'blather', '>= 1.2.0'

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'

group :test do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter', '~> 0.3.0' #for tests generated for Jenkins
  gem 'factory_bot_rails'
  gem 'simplecov'
  gem 'net-ssh', "< 5.0.0" #version as from 5.0.0 require ruby > 2.2.6
  gem 'net-ssh-multi'
	#gem 'pkgr', '>= 1.4.4' #pkgr comes with debian-8 buildpack as from 1.4.4, but is not compatible with rails 3.0 (incompatible dependencies on rake and thor)
end


