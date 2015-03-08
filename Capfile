# We want to share app data between Chef and Capistrano. So load
# it here from the appropriate .json.erb file(s).
require_relative File.join "config", "madscience_config.rb"

json_by_vm = get_chef_json_by_vm
ENV['INSTALL_HOST'] ||= json_by_vm.keys.first
$install_host = ENV['INSTALL_HOST']
raise "You must specify an install host or only have one host!" unless $install_host

$cap_json = json_by_vm[$install_host]
raise "Your specified host #{$install_host.inspect} doesn't seem to be in the nodes dir!" unless $cap_json

# We must specify which application to install. There could be multiple to choose from.
# It's okay to have no Ruby apps at all, but then don't call Capistrano to install one.
ENV['INSTALL_APP'] ||= $cap_json["ruby_apps"].keys.first

raise "You must specify an INSTALL_APP variable or just have one app!" unless ENV['INSTALL_APP']
$app_data = $cap_json["ruby_apps"][ENV['INSTALL_APP']]
raise "Can't find app #{ENV['INSTALL_APP'].inspect} under ruby_apps in JSON!" unless $app_data

# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'
require 'capistrano/rvm'
require 'capistrano/rails' unless $app_data["rails"] == "false" # This should only be for Rails apps...

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
# require 'capistrano/rvm'
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
# require 'capistrano/bundler'
# require 'capistrano/rails/assets'
# require 'capistrano/rails/migrations'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
