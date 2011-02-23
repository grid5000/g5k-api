require 'rubygems'

# Attempts to use a vendored Bundler, if any
vendored_gems = File.expand_path(
  '../../vendor/ruby/1.9.1/gems', __FILE__
)

vendored_bundler = Dir["#{vendored_gems}/bundler-*/lib"].sort.last

if !vendored_bundler.nil? && !$LOAD_PATH.include?(vendored_bundler)
  $LOAD_PATH.unshift(vendored_bundler)
end

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)
