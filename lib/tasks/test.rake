config = Api::Application::CONFIG['oar']

namespace :db do
  namespace :oar do
    desc "Load seed data into OAR2 database. Use an alternative seed file by setting the SEED environment variable."
    task :seed do
      fail "You should be executing this with RAILS_ENV=test or with SEED pointing to a file" unless Rails.env == "test" && !ENV.has_key?('SEED')
      seed = ENV['SEED'] || File.expand_path("../../../spec/fixtures/oar2_2011-01-07.sql", __FILE__)
      fail "Can't load seed file located at #{seed.inspect}" unless File.exist?(seed)
      cmd = "PGPASSWORD=#{config['password']} psql -U #{config['username']} -h #{config['host']} -p #{config['port'] || 5432} #{config['database']} < \"#{seed}\""
      puts "Executing " + cmd
      system cmd
    end

    desc "Drop OAR2 database"
    task :drop do
      cmd = "export PGPASSWORD=#{config['password']} && dropdb  -U #{config['username']} -h #{config['host']} -p #{config['port'] || 5432} #{config['database']}"
      puts "Executing " + cmd
      system cmd
    end

    desc "Create OAR2 database (requires sudo)"
    task :create do
      cmd = "sudo su -c \"createdb -O root oar2_test -E 'UTF8' -T template0\" postgres"
      puts "Executing " + cmd
      system cmd
    end
  end
end



