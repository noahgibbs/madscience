# We want to share app data between Chef and Capistrano. So load
# it here from the appropriate .json.erb file.
require "erubis"
require "json"
json_erb_path = File.join(File.dirname(__FILE__), "nodes", "all_nodes.json.erb")
eruby = Erubis::Eruby.new File.read(json_erb_path)

$cap_json = JSON.parse eruby.result({})
raise "Can't read JSON file for vagrant Capistrano node!" unless $cap_json

# We must specify which application to install. There could be multiple.
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
