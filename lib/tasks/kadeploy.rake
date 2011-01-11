KADEPLOY_DIR = File.join(Rails.root, "lib", "kadeploy")

namespace :kadeploy do
  desc "Upgrade kadeploy3 library to newest revision. You can also set a specific SVN revision using REV=176 for instance."
  task :upgrade do
    cmd = "svn export svn://scm.gforge.inria.fr/svn/kadeploy3/tags/3.1-3/src/lib #{KADEPLOY_DIR} --force"
    cmd+= " -r #{ENV['REV']}" if ENV['REV']
    puts "Executing #{cmd.inspect}..."
    system cmd
  end
end
