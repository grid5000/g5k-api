ROOT_DIR = File.expand_path("../../..", __FILE__)
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")
VERSION_FILE = File.join(ROOT_DIR, "lib", "grid5000", "version.rb")

NAME = ENV['PKG_NAME'] || "g5k-api"
USER_NAME = `git config --get user.name`.chomp
USER_EMAIL = `git config --get user.email`.chomp

LSBDISTCODENAME= `lsb_release -s -c`.chomp

require VERSION_FILE

PACKAGING_DIR = '/tmp/'+NAME+'-'+Grid5000::VERSION

def in_working_dir(dir,&block)
  #Dir.choidr does not change ENV['PWD']
  old_wd=ENV['PWD']
  Dir.chdir(dir) do
    ENV['PWD']=dir
    yield
  end
  ENV['PWD']=old_wd
end

def without_bundle_env(forced_values={}, &block)
  to_clean=["BUNDLE_GEMFILE","RUBYOPT"]
  saved_values={}
  to_clean.each do |env_value|
    saved_values[env_value]=ENV[env_value]
    if forced_values.has_key?(env_value)
      ENV[env_value]=forced_values[env_value]
    else
      ENV.delete(env_value)
    end
  end
  
  yield
  
  to_clean.each do |env_value|
    ENV[env_value]=saved_values[env_value]
  end
end

def bump(index)  
  fragments = Grid5000::VERSION.split(".")
  fragments[index] = fragments[index].to_i+1
  ((index+1)..2).each{|i|
    fragments[i] = 0
  }
  new_version = fragments.join(".")

  changelog = File.read(CHANGELOG_FILE)
  last_commit = changelog.scan(/\s+\* ([a-f0-9]{7}) /).flatten[0]

  cmd = "git log --oneline"
  cmd << " #{last_commit}..HEAD" unless last_commit.nil?

	commit_logs=`#{cmd}`.split("\n")
	purged_logs=commit_logs.reject{|l| l =~ / v#{Grid5000::VERSION}/}.reject{|l| l =~ /Commit version #{Grid5000::VERSION}/}
	if purged_logs.size == 0
	  puts 'No real changes except version changes since last version bump. Aborting unless EMPTYBUMP set'
		return unless ENV['EMPTYBUMP']
  end	
	if USER_NAME==""
	  puts 'No git user: running in Vagrant box ? Use git config --global user.name "firstname lastename" before bumping version'  
		return
  end	 
  content_changelog = [
    "#{NAME} (#{new_version}-1) #{LSBDISTCODENAME}; urgency=low",
    "",
    purged_logs.map{|l| "  * #{l}"}.join("\n"),
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
    sh "git commit -m 'Commit version #{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
    puts "Tagging the release"
    sh "git tag -a v#{new_version} -m \"v#{new_version} tagged by rake package:bump:[patch|minor|major]\""
    puts "INFO: git push --follow-tags (push with relevant tags) required for package publication by gitlab CI/CD"
  end
end

namespace :package do
  task :setup do
    mkdir_p "#{PACKAGING_DIR}/pkg"
    # remove previous versions
    rm_rf "#{PACKAGING_DIR}/pkg/#{NAME}_*.deb"
    sh "mkdir -p pkg/ && git archive HEAD > /tmp/#{NAME}.tar"
  end
  
  desc "Bundle the dependencies for the current platform"
  task :bundle => :setup do
    in_working_dir(PACKAGING_DIR) do
      without_bundle_env({}) do 
        BUNDLER_VERSION=`bundle --version | cut -d ' ' -f 3`.chomp
        %w{bin gems specifications}.each{|dir|
          rm_rf "vendor/ruby/#{RUBY_VERSION}/#{dir}"
        }
        sh "bundle install --deployment --without test development --path vendor"
        # Vendor bundler
        sh "gem install bundler --no-ri --no-rdoc --version #{BUNDLER_VERSION} -i #{PACKAGING_DIR}/vendor/bundle/ruby/#{RUBY_VERSION}/"
        %w{cache doc}.each{|dir|
          rm_rf "vendor/bundle/ruby/#{RUBY_VERSION}/#{dir}"
        }
      end
    end
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

  namespace :build do
    desc "Build debian package with pkgr"
    task :debian_pkgr do
      sh "pkgr package . --version #{Grid5000::VERSION} --name #{NAME} --auto"
    end 
    desc "Build debian package with our own scripts"
    task :debian => :'package:setup' do
      if Process.uid == 0
        sudo=""
      else
        sudo='sudo '
      end
      commands=[
        "#{sudo}apt-get -y --no-install-recommends install devscripts build-essential equivs",
        "#{sudo}mk-build-deps -ir -t 'apt-get -y --no-install-recommends'",
        "rm -rf /tmp/#{NAME}"
      ]
      for cmd in commands do
        sh cmd
      end
#        cmd = "#{sudo}apt-get install #{pkg_dependencies.join(" ")} git-core dh-make dpkg-dev libicu-dev --yes && rm -rf /tmp/#{NAME}"

      Dir.chdir('/tmp') do
        sh "tar xf #{NAME}.tar -C #{PACKAGING_DIR}"
        Dir.chdir(PACKAGING_DIR) do
          Rake::Task[:'package:bundle'].invoke
          sh "dpkg-buildpackage -us -uc -d"
        end
      end
      sh "cp #{PACKAGING_DIR}/../#{NAME}_#{Grid5000::VERSION}*.deb pkg/"     
    end
  end                            

end

