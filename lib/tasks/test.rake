config = Api::Application::CONFIG['oar']

namespace :db do
  namespace :oar do
    desc "Load seed data into OAR2 database. Use an alternative seed file by setting the SEED environment variable."
    task :seed do
      fail "You should be executing this with RACK_ENV=test" unless Rails.env == "test" 
      seed = ENV['SEED'] || File.expand_path("../../../spec/fixtures/oar2_2011-01-07.sql", __FILE__)
      fail "Can't load seed file located at #{seed.inspect}" unless File.exist?(seed)
      cmd = "PGPASSWORD=#{config['password']} psql -U #{config['username']} -h #{config['host']} -p #{config['port'] || 5432} #{config['database']} < \"#{seed}\""
      puts "Executing " + cmd
      system cmd
    end

  end
end



