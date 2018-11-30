# Copyright (c) 2010-2012 INRIA Rennes Bretagne Atlantique by Cyril Rohr (Grid'5000 and BonFIRE projects)
# Copyright (c) 2015-2018 INRIA Rennes Bretagne Atlantique by David Margery (Grid'5000)

ROOT_DIR = File.expand_path("../../..", __FILE__)
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")
VERSION_FILE = File.join(ROOT_DIR, 'lib', 'grid5000', 'version.rb')

NAME = ENV['PKG_NAME'] || "g5k-api"

require VERSION_FILE

PACKAGING_DIR = '/tmp/'+NAME+'_'+Grid5000::VERSION
PACKAGES_DIR = File.join(ROOT_DIR, 'pkg')

def lsb_dist_codename
   return `lsb_release -s -c`.chomp
end

def date_of_commit(tag_or_commit)
  date=`git show --pretty=tformat:"MyDate: %aD" #{tag_or_commit}`.chomp
  if date =~ /MyDate\: (.*)$/
    date=$1
  end
  date
end

def deb_version_from_date(date)
  Time.parse(date).strftime("%Y%m%d%H%M%S")
end

def deb_version_of_commit(tag_or_commit)
  deb_version_from_date(date_of_commit(tag_or_commit))
end

def purged_commits_between(version1,version2)
  cmd = "git log --oneline"
  cmd << " #{version1}..#{version2}" unless version1.nil?
  commit_logs=`#{cmd}`.split("\n")
  purged_logs=commit_logs.reject{|l| l =~ / v#{Grid5000::VERSION}/}.
                reject{|l| l =~ / v#{version2}/}.
                reject{|l| l =~ /Commit version #{Grid5000::VERSION}/}
  purged_logs
end

def generate_changelog_entry(version, deb_version, logs, author, email, date)
  return [
    "#{NAME} (#{version.gsub('_','~')}-#{deb_version}) #{lsb_dist_codename}; urgency=low",
    "",
    logs.map{|l| "  * #{l}"}.join("\n"),
    "",
    " -- #{author} <#{email}>  #{date}",
    ""
  ].join("\n")
end

def changelog_for_version(version, deb_version, change_logs)
  cmd="git show #{version}"
  tagger=`#{cmd}`
  if tagger =~ /Tagger\: ([^<]*)<([^>]*)>/
    author=$1
    email=$2
  elsif tagger =~ /Author\: ([^<]*)<([^>]*)>/
    author=$1
    email=$2
  else
    puts "#{cmd} has #{tagger} as output: could not find Tagger or Author"
  end
  date=date_of_commit(version)
  if deb_version.nil?
    deb_version=deb_version_from_date(date)
  end
  return generate_changelog_entry(version, deb_version, change_logs, author, email, date)
end

def generate_changelog
  versions = `git tag`.split("\n")
  versions.sort! do |v1,v2|
    major1,minor1,rest1=v1.split('.')
    major2,minor2,rest2=v2.split('.')
    unless major1==major2
      major1 <=> major2
    else
      unless minor1==minor2
        minor1 <=> monor2
      else
        patch1,rc1=rest1.split('_rc')
        patch2,rc2=rest2.split('_rc')
        unless patch1==patch2
          patch1.to_i <=> patch2.to_i
        else
          rc1.to_i <=> rc2.to_i
        end
      end
    end
  end
  versions.reject! {|v| v !~ /[0-9]+\.[0-9]+\..*/}
  change_logs=[]
  previous_version=versions.shift
  change_logs << changelog_for_version(previous_version, nil, ["First version tagged for packaging"])
  versions.each do |version|
    purged_logs=purged_commits_between(previous_version, version)
    if purged_logs.empty?
      purged_logs=["Retagged #{previous_version}. No other changes"]
    end
    change_logs << changelog_for_version(version, nil, purged_logs)
    previous_version=version
  end
  change_logs.reverse.join("\n")
end

def update_changelog(changelog_file,new_version)
  content_changelog=''
  if File.exists?(changelog_file)
    changelog=File.read(changelog_file)
    last_commit = changelog.scan(/\s+\* ([a-f0-9]{7}) /).flatten[0]
    deb_version=deb_version_of_commit('HEAD')
    purged_logs=purged_commits_between(last_commit, 'HEAD')
    if purged_logs.size != 0
      user_name=`git config --get user.name`.chomp
      if user_name==""
        puts 'No git user: running in Vagrant box ? Use git config --global user.name "firstname lastname" before bumping version'
        return
      end
      user_email=`git config --get user.email`.chomp
      content_changelog = generate_changelog_entry(new_version,
                                                   deb_version,
                                                   purged_logs,
                                                   user_name,
                                                   user_email,
                                                   Time.now.strftime("%a, %d %b %Y %H:%M:%S %z"))
      File.open(changelog_file, "w+") do |f|
        f << content_changelog+"\n"
        f << changelog
      end
    end
  else
    warn "Update_changelog called on inexistant file #{changelog_file}"
  end
  return content_changelog.size > 0
end

def bump(index)
  fragments = Grid5000::VERSION.split(".")
  fragments[index] = fragments[index].to_i+1
  ((index+1)..2).each{|i|
    fragments[i] = 0
  }
  new_version = fragments.join(".")

  content_version = File.read(VERSION_FILE).gsub(
    Grid5000::VERSION,
    new_version
  )

  File.open(VERSION_FILE, "w+") do |f|
    f << content_version
  end

  changed=update_changelog(CHANGELOG_FILE, new_version)

  unless changed
    puts 'No real changes except version changes since last version bump. Aborting unless EMPTYBUMP set'
    exit -1 unless ENV['EMPTYBUMP']
  end

  puts "Generated changelog for version #{new_version}."
  unless ENV['NO_COMMIT']
    puts "Committing changelog and version file..."
    sh "git commit -m 'Commit version #{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
    unless ENV['NO_COMMIT']
      puts "Tagging the release"
      sh "git tag -a v#{new_version} -m \"v#{new_version} tagged by rake package:bump:[patch|minor|major]\""
      puts "INFO: git push --follow-tags (push with relevant tags) required for package publication by gitlab CI/CD"
    end
  end
end

namespace :package do
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
    desc "Prepare dirs for building debian package"
    task :prepare do
      version = Grid5000::VERSION
      # prepare the dir where the result will be stored
      mkdir_p "#{PACKAGES_DIR}"

      # make sure no pending changes need to be commited to repository
      uncommitted_changes=`git status --untracked-files=no --porcelain`
      if uncommitted_changes != ""
        # Gemfile.lock will include bundle version used. It changes between debian versions
        files=uncommitted_changes.scan(/\w\s(.*)$/).flatten.reject{|f| ["Gemfile.lock"].include?(f)}
        if files.size > 0
          STDERR.puts "Unexpected diff in #{files}:"
          STDERR.puts `git diff`
          fail "You are building from a directory with uncommited files in git. Please commit pending changes so there is a chance the build can be traked back to a specific state in the repository\n#{uncommitted_changes}"
        else
          STDERR.puts "Expected diff:"
          STDERR.puts `git diff`
        end
      end

      # prepare the build directory
      mkdir_p "#{PACKAGING_DIR}/pkg"
      # remove previous versions built from the build directory
      rm_rf "#{PACKAGING_DIR}/pkg/#{NAME}_*.deb"

      # extract the commited state of the repository to the build directory
      sh "git archive HEAD > /tmp/#{NAME}_#{version}.tar"
      Dir.chdir("/tmp") do
        mkdir_p "#{NAME}_#{version}"
        sh "tar xf #{NAME}_#{version}.tar -C #{NAME}_#{version}"
        sh "rm #{NAME}_#{version}.tar"
      end
    end

    desc "Build debian package"
    task :debian => :prepare do
      if Process.uid == 0
        sudo=""
      else
        sudo='sudo '
      end
      commands=[
        "#{sudo}apt-get -y --no-install-recommends install devscripts build-essential equivs",
        "#{sudo}mk-build-deps -ir -t 'apt-get -y --no-install-recommends'",
      ]
      for cmd in commands do
        sh cmd
      end

      update_changelog(File.join(PACKAGING_DIR,'debian','changelog'), Grid5000::VERSION)
      Dir.chdir('/tmp') do
        Dir.chdir(PACKAGING_DIR) do
          sh "dpkg-buildpackage -us -uc -d"
        end
      end
      sh "cp #{PACKAGING_DIR}/../#{NAME}_#{Grid5000::VERSION}*.deb pkg/"
    end
  end

  namespace :changelog do
    desc "Generate a changelog from git log and tags and save it in #{CHANGELOG_FILE}"
    task :generate do
      File.open(CHANGELOG_FILE, "w+") do |f|
        f << generate_changelog
      end
    end

    desc "Show what a generated changelog from git log and tags would look like"
    task :show do
      puts generate_changelog
    end

  end
end
