#
# Cookbook Name:: rails_server
# Recipe:: default
#

# First, apt-get update. We do that with the run_list in
# the Node JSON file.

# Your application(s) shouldn't run as root.
# Each should have a username assigned to it.

# RVM Config
# https://github.com/fnichol/chef-rvm

# Specifically, we want to install RVM in the app user's directory
# so that we can install gems into it during our deploys later.
# We don't want to give the Rails user permissions on the system
# directories, but we also don't want to prevent later non-Chef
# installs by locking down the gem directories and not letting
# the Rails user get at it.
#
# This is a constant struggle in many companies. The developers
# favor RVM so that they can install gems (libraries) freely,
# and the Ops folks lock down the gem directories so that the
# application, if hacked, can't install new ones.

# Install Ruby 2.0 for the application.
package "gawk" # For Ubuntu, this is from "rvm requirements"

users = node["users"].keys

# Use RVM's user_install recipe. Seems to be no LWRP equivalent.
# That means setting attributes.
node.default["rvm"]["user_installs"] = users.map { |u| { 'user' => u } }
include_recipe "rvm::user_install"

users.each do |app_user|
  # Install RVM and Ruby for each user
  rvm_default_ruby "2.0.0-p481" do
    user app_user
  end

  # Test RVM install
  rvm_shell 'echo ruby' do
    user app_user
    code 'echo My Ruby is `rvm current`!'
    returns [0]
  end

  directory "/home/#{app_user}/.ssh" do
    owner app_user
    group app_user
    mode "0700"
  end

  file "/home/#{app_user}/.ssh/authorized_keys" do
    owner app_user
    group app_user
    mode "0700"
    content node['authorized_keys']
  end
end

# Who owns the top-level deploy directory?
directory "/var/www" do
  owner "root"
  group "root"
  mode "0755"
end

# Create directories for Capistrano to deploy to
node["rails_apps"].each do |app_name, app_data|
  directory "/var/www/#{app_name}" do
    owner app_data["user"]
    group app_data["user"]
    mode "0755"
  end
end
