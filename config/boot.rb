require 'rubygems'

# YAML parsing fix
if RUBY_VERSION > '1.9.0'
  require 'yaml'
  YAML::ENGINE.yamler= 'syck'
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
