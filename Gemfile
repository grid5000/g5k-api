#source 'http://g5k-campaign.gforge.inria.fr/pkg'
source 'https://rubygems.org'

gem 'rake', '>= 11.1.2'
gem 'rails', '~> 3.0.0'
gem 'eventmachine', '>= 1.0.0'
gem 'rack-fiber_pool', '~> 0.9'
gem 'em-synchrony', '~> 0.2'
gem 'em-http-request', '~> 0.2'
gem "mysql2", "~>0.2.0"
gem "ruby-mysql", :require => "mysql"
gem 'addressable', '~> 2.2'
gem 'thin', '~> 1.5.0'
gem 'state_machine', '~> 0.9'
gem 'gitlab-grit', :require => ['grit']
gem 'syslogger'
gem 'haml'
gem 'rack-jsonp'
gem 'pg'
gem 'em-postgresql-adapter', :git => 'git://github.com/cadicallegari/em-postgresql-adapter.git', :ref => '2a0d31b663b7'
gem 'nokogiri', '~> 1.5.6' #oldest version that blather handles

gem 'blather', '>= 1.2.0'

group :test, :development do
  gem 'webmock'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'autotest'
  gem 'autotest-growl'
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'net-ssh-multi'
	#gem 'pkgr', '>= 1.4.4' #pkgr comes with debian-8 buildpack as from 1.4.4, but is not compatible with rails 3.0 (incompatible dependencies on rake and thor)
  #gem 'capistrano'
  gem 'g5k-campaign', :git => 'https://gforge.inria.fr/git/g5k-campaign/g5k-campaign.git', :ref => 'cac93c26c7c998da96182980736b4d17fb070570' # '~> 0.9.7'
end


