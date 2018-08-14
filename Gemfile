#source 'http://g5k-campaign.gforge.inria.fr/pkg'
source 'https://rubygems.org'

gem 'rake'
gem 'rails', '~> 3.2.0'
# jQuery is the default JavaScript library in Rails 3.1
gem 'jquery-rails'

gem 'eventmachine'
gem 'rack-fiber_pool', '~> 0.9'
gem 'em-synchrony'
gem 'em-http-request'
gem "mysql2", '~> 0.3.6'
gem "ruby-mysql", :require => "mysql"
gem 'addressable', '~> 2.2'
gem 'thin', '~> 1.5.0'
gem 'state_machine'
gem 'gitlab-grit', :require => ['grit']
gem 'syslogger'
gem 'haml', '~> 4.0.4'
gem 'rack-jsonp'
gem 'pg', '< 1.0.0'
gem 'em-postgresql-adapter', :git => 'https://github.com/grid5000/em-postgresql-adapter.git'
#gem 'activerecord-em_postgresql-adapter'
#gem 'em-postgresql-adapter', :git => 'git://github.com/cadicallegari/em-postgresql-adapter.git', :ref => '2a0d31b663b7'
gem 'nokogiri', '~> 1.5.6' #oldest version that blather handles

gem 'blather', '>= 1.2.0'

group :assets do
  gem 'sass-rails',   "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier',     ">= 1.0.3"
end

group :test do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter', '~> 0.3.0' #for tests generated for Jenkins
  gem 'autotest'
  gem 'autotest-growl'
  gem 'rspec-autotest'
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'net-ssh', "< 5.0.0" #version as from 5.0.0 require ruby > 2.2.6
  gem 'net-ssh-multi'
	#gem 'pkgr', '>= 1.4.4' #pkgr comes with debian-8 buildpack as from 1.4.4, but is not compatible with rails 3.0 (incompatible dependencies on rake and thor)
  #gem 'capistrano'
  gem 'g5k-campaign', :git => 'https://gforge.inria.fr/git/g5k-campaign/g5k-campaign.git', :ref => 'cac93c26c7c998da96182980736b4d17fb070570' # '~> 0.9.7'
end


