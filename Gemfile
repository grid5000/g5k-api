#source 'http://g5k-campaign.gforge.inria.fr/pkg'
source 'https://rubygems.org'

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
#gem 'grit'
gem 'gitlab-grit', :require => ['grit']
gem 'syslogger'
gem 'haml'
gem 'rack-jsonp'
gem 'pg', '~> 0.18.0' #as from 0.18.1, requires ruby 1.9.3
gem 'em-postgresql-adapter', :git => 'git://github.com/leftbee/em-postgresql-adapter.git', :branch => 'pre-3_1'

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
  gem 'net-ssh-multi', '~> 1.1.0' #need to constrain this other g5k-campaign will pull a dependency that is too recent
  gem 'capistrano'
  gem 'g5k-campaign', :git => 'https://gforge.inria.fr/git/g5k-campaign/g5k-campaign.git', :ref => 'cac93c26c7c998da96182980736b4d17fb070570' # '~> 0.9.7'

end


