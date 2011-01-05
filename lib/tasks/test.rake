require 'rspec/core/rake_task'

# MYSQL_INIT_SCRIPT = ENV['MYSQL_INIT_SCRIPT'] || '/usr/local/mysql/support-files/mysql.server'

namespace :test do
  # desc "Setup test environment"
  # task :setup do
  #   cmd = "sudo #{MYSQL_INIT_SCRIPT} start"
  #   system cmd
  # end
  # 
  # desc "Destroy test environment"
  # task :teardown do
  #   cmd = "sudo #{MYSQL_INIT_SCRIPT} stop"
  #   system cmd
  # end
  
  desc "Run Test coverage"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = 'spec/**/*_spec.rb'
    t.rcov_opts = ['-Ispec', '--exclude', 'gems', '--exclude', 'spec', '--exclude', 'config', '--exclude', 'app/metal']
  end
  
end



