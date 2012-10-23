KADEPLOY_DIR = File.join(Rails.root, "lib", "kadeploy")

namespace :kadeploy do
  desc "Upgrade kadeploy3 library to newest revision. You can also set a specific GIT branch using BRANCH=3.1.5 for instance."
  task :upgrade do
    cmd = "git clone git://scm.gforge.inria.fr/kadeploy3/kadeploy3.git /tmp/kadeploy3"
    cmd+= " -b #{ENV['BRANCH']}" if ENV['BRANCH']
    puts "Executing (clone) #{cmd.inspect}..."
    system cmd
    cmd = "cp -rf /tmp/kadeploy3/src/lib/*.rb #{KADEPLOY_DIR}"
    puts "Executing (copy) #{cmd.inspect}..."
    system cmd
  end
end
