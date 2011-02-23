ROOT_DIR = File.expand_path("../../..", __FILE__)
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")
VERSION_FILE = File.join(ROOT_DIR, "lib", "grid5000", "version.rb")

NAME = "g5kapi"
BUILD_MACHINE = ENV['BUILD_MACHINE'] || "debian-build"
USER_NAME = `git config --get user.name`.chomp
USER_EMAIL = `git config --get user.email`.chomp
require VERSION_FILE

def bump(index)
  fragments = Grid5000::VERSION.split(".")
  fragments[index] = fragments[index].to_i+1
  new_version = fragments.join(".")

  changelog = File.read(CHANGELOG_FILE)
  last_commit = changelog.scan(/\s+\* ([a-z0-9]{7}) /).flatten[0]

  cmd = "git log --oneline"
  cmd << " #{last_commit}..HEAD" unless last_commit.nil?
  content_changelog = [
    "#{NAME} (#{new_version}-1) unstable; urgency=low",
    "",
    `#{cmd}`.split("\n").reject{|l| l =~ / v#{Grid5000::VERSION}/}.map{|l| "  * #{l}"}.join("\n"),
    "",
    " -- #{USER_NAME} <#{USER_EMAIL}>  #{Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")}",
    "",
    changelog
  ].join("\n")

  content_version = File.read(VERSION_FILE).gsub(
    Grid5000::VERSION,
    new_version
  )

  File.open(VERSION_FILE, "w+") do |f|
    f << content_version
  end
  File.open(CHANGELOG_FILE, "w+") do |f|
    f << content_changelog
  end

  puts "Generated changelog for version #{new_version}."
  unless ENV['NOCOMMIT']
    puts "Committing changelog and version file..."
    system "git commit -m 'v#{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
  end
end

namespace :package do
  task :setup do
    mkdir_p "pkg"
    # remove previous versions
    rm_f "pkg/#{NAME}_*.deb"
  end

  desc "Bundle the dependencies for the current platform"
  task :bundle do
    rm_rf "vendor"
    system "PATH=/var/lib/gems/1.9.1/bin:$PATH bundle install"
    rm_rf "vendor/ruby/1.9.1/cache"
  end

  namespace :bump do
    desc "Increment the patch fragment of the version number by 1"
    task :patch do
      bump(2)
    end
    desc "Increment the minor fragment of the version number by 1"
    task :minor do
      bump(1)
    end
    desc "Increment the major fragment of the version number by 1"
    task :major do
      bump(0)
    end
  end

  desc "Build the binary package"
  task :build do
    system "dpkg-buildpackage -us -uc -d"
  end

  desc "Generates the .deb"
  task :debian => [:bundle, :build]

  desc "Execute the build process on a machine called `#{BUILD_MACHINE}`"
  task :remote_build => :setup do
    system "ssh #{BUILD_MACHINE} 'mkdir -p ~/dev/#{NAME}'"
    system "rsync -r -p . #{BUILD_MACHINE}:~/dev/#{NAME}"
    system "ssh #{BUILD_MACHINE} 'cd ~/dev/#{NAME} && PATH=/var/lib/gems/1.9.1/bin:$PATH rake -f lib/tasks/packaging.rake package:debian'"
    system "scp #{BUILD_MACHINE}:~/dev/*.deb pkg/" if $?.exitstatus==0
  end

  desc "Package the required dependencies as .deb"
  task :dependencies => :setup do
    system "ssh #{BUILD_MACHINE} 'sudo gem install fpm && PATH=/var/lib/gems/1.9.1/bin:$PATH fpm -s gem -t deb bundler'"
    system "scp #{BUILD_MACHINE}:~/rubygem-bundler*.deb pkg/" if $?.exitstatus==0
  end

  desc "Uploads the .deb on apt.grid5000.fr and generate the index"
  task :release do
    system "scp pkg/*.deb apt.grid5000.fr:/var/www/#{NAME}/"
    system "ssh apt.grid5000.fr 'cd /var/www/#{NAME} && sudo dpkg-scanpackages . | gzip -f9 > Packages.gz'" if $?.exitstatus==0
  end

  desc "Remotely build the app and its dependencies, then release them on apt.grid5000.fr"
  task :full => [:dependencies, :remote_build, :release]
end

