require 'rspec/core/rake_task'

config = Api::Application::CONFIG['oar']
ActiveRecord::Base.establish_connection(config)

namespace :db do
  namespace :oar do
    desc "Create OAR2 database (on the same mysql server than default database)."
    task :create do
      ActiveRecord::Base.connection.create_database('oar2')
    end

    desc "Load seed data into OAR2 database. Use an alternative seed file by setting the SEED environment variable."
    task :seed do
      seed = ENV['SEED'] || File.expand_path("../../../spec/fixtures/oar2_2011-01-07.sql", __FILE__)
      fail "Can't load seed file located at #{seed.inspect}" unless File.exist?(seed)
      cmd = "mysql -u #{config['username']} -h #{config['host']} --password= #{config['password']} -P #{config['port'] || 3306} -D #{config['database']} < \"#{seed}\""
      puts "Executing " + cmd
      system cmd
    end

    desc "Setup test OAR2 database"
    task :setup => [:create, :seed]
  end
end

namespace :test do
  desc "Run Test coverage"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = 'spec/**/*_spec.rb'
    t.rcov_opts = ['-Ispec', '--exclude', 'gems', '--exclude', 'spec', '--exclude', 'config', '--exclude', 'app/metal']
  end

end



