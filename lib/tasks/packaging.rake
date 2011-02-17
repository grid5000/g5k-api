ROOT_DIR = File.expand_path("../..", __FILE__)

namespace :package do
  task :setup do
    mkdir_p "pkg"
  end
  
  desc "Bundle the dependencies for the current platform"
  task :bundle do
    rm_rf "vendor"
    system "PATH=/var/lib/gems/1.9.1/bin:$PATH bundle install"
  end

  desc "Build the binary package"
  task :build do
    system "dpkg-buildpackage -us -uc -d"
  end

  desc "Generates the .deb"
  task :debian => [:bundle, :build]

  desc "Execute the build process on a machine called `debian-build`"
  task :remote_build => :setup do
    system "ssh debian-build 'mkdir -p ~/dev/g5kapi'"
    system "rsync -r -p . debian-build:~/dev/g5kapi"
    system "ssh debian-build 'cd ~/dev/g5kapi && PATH=/var/lib/gems/1.9.1/bin:$PATH rake -f lib/tasks/packaging.rake package:debian'"
    system "scp debian-build:~/dev/*.deb pkg/" if $?.exitstatus==0
  end
  
  desc "Package the required dependencies as .deb"
  task :dependencies => :setup do
    system "ssh debian-build 'sudo gem install fpm && PATH=/var/lib/gems/1.9.1/bin:$PATH fpm -s gem -t deb bundler'"
    system "scp debian-build:~/rubygem-bundler*.deb pkg/" if $?.exitstatus==0
  end
  
  desc "Uploads the .deb on apt.grid5000.fr and generate the index"
  task :release do
    system "scp pkg/*.deb apt.grid5000.fr:/var/www/g5kapi/"
    system "ssh apt.grid5000.fr 'cd /var/www/g5kapi && sudo dpkg-scanpackages . | gzip -f9 > Packages.gz'" if $?.exitstatus==0
  end
  
  desc "Remotely build the app and its dependencies, then release them on apt.grid5000.fr"
  task :full => [:dependencies, :remote_build, :release]
end

