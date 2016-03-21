ROOT_DIR = File.expand_path("../../..", __FILE__)
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")
VERSION_FILE = File.join(ROOT_DIR, "lib", "grid5000", "version.rb")

NAME = ENV['PKG_NAME'] || "g5k-api"
BUILD_MACHINE = ENV['BUILD_MACHINE'] || "debian-build"
USER_NAME = `git config --get user.name`.chomp
USER_EMAIL = `git config --get user.email`.chomp
BUNDLER_VERSION = "1.7.6"

require VERSION_FILE

def bump(index)  
  fragments = Grid5000::VERSION.split(".")
  fragments[index] = fragments[index].to_i+1
  ((index+1)..2).each{|i|
    fragments[i] = 0
  }
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
    sh "git commit -m 'v#{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
  end
end

namespace :package do
  task :setup do
    mkdir_p "pkg"
    # remove previous versions
    rm_rf "pkg/#{NAME}_*.deb"
  end
  
  desc "Bundle the dependencies for the current platform"
  task :bundle do
    %w{bin gems specifications}.each{|dir|
      rm_rf "vendor/ruby/1.9.1/#{dir}"
    }
    # Install dependencies
    sh "which bundle || gem1.9.1 install bundler --version #{BUNDLER_VERSION}"
    #sh "export CFLAGS='-Wno-error=format-security' && bundle install --deployment --without test development"
    sh "bundle install --deployment --without test development"
    # Vendor bundler
    sh "gem1.9.1 install bundler --no-ri --no-rdoc --version #{BUNDLER_VERSION} -i vendor/bundle/ruby/1.9.1/"
    %w{cache doc}.each{|dir|
      rm_rf "vendor/bundle/ruby/1.9.1/#{dir}"
    }
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
    sh "dpkg-buildpackage -us -uc -d"
  end

  desc "Generates the .deb"
  task :debian => [:setup, :bundle, :build]
end

