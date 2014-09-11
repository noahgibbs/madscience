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

# Install RVM and Ruby 2.0 for the application.
package "gawk" # For Ubuntu, this is from "rvm requirements"

users = node["users"].keys

# Use RVM's user_install recipe. Seems to be no LWRP equivalent.
# That means setting attributes.
node.default["rvm"]["user_installs"] = users.map { |u| { 'user' => u } }
include_recipe "rvm::user_install"
include_recipe "runit"
include_recipe "database::mysql"

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

# Create databases for applications
node["ruby_apps"].each do |app_name, app_data|
  db_name = app_data["db_name"] || (app_name.gsub("-", "_") + "_production")
  mysql_database db_name do
    connection(
      :host     => 'localhost',
      :username => 'root',
      :password => node['mysql']['server_root_password']
    )
    action :create
  end
end

# Create application directories for Capistrano to deploy to
node["ruby_apps"].each do |app_name, app_data|
  directory "/var/www/#{app_name}" do
    owner app_data["user"]
    group app_data["user"]
    mode "0755"
  end

  directory "/var/www/#{app_name}/shared" do
    owner app_data["user"]
    group app_data["user"]
    mode "0755"
  end

  directory "/var/www/#{app_name}/shared/log" do
    owner app_data["user"]
    group app_data["user"]
    mode "0755"
  end
end

# Create services, run files and other runit and nginx infrastructure
port = 8800 # Assign consecutive Unicorn port ranges starting at 8800
node["ruby_apps"].each do |app_name, app_data|
  ruby_version = "ruby-2.0.0-p481" # TODO: Make settable per-app
  rvm_dir = "/home/#{app_data["user"]}/.rvm/"

  vars = {
    :rvm_dir => rvm_dir,
    :home_dir => "/home/#{app_data["user"]}/",
    :app_dir => "/var/www/#{app_name}",
    :app_name => app_name,
    :user => app_data["user"],
    :group => app_data["user"],
    :ruby_version => ruby_version,
    :wrapper_dir => "#{rvm_dir}/wrappers/#{ruby_version}",
    :ruby_bin => "#{rvm_dir}/wrappers/#{ruby_version}/ruby",
    :env_vars => app_data["env_vars"] || {},
    :unicorn_arguments => app_data["unicorn_arguments"] || "",  # Extra arguments to unicorn
    :unicorn_port => port,                                      # Unicorn port number
    :log_run_arguments => app_data["log_run_arguments"] || "",  # Extra arguments to svlogd
    :chpst_arguments => app_data["chpst_arguments"] || "",      # Extra arguments to chpst
    :extra_code => app_data["extra_run_code"] || "",            # Additional bash code in run script
    :extra_log_code => app_data["extra_log_code"] || "",        # Additional bash code in log script
  }

  runit_service app_name do
    owner app_data["user"]
    group app_data["user"]
    template_name "rails-app"
    log_template_name "rails-app"
    options vars
  end

  template "#{node['nginx']['dir']}/sites-available/#{app_name}.conf" do
    source "nginx-site.conf.erb"
    mode "0644"
    variables({:app_dir => vars[:app_dir],
      :app_name => app_name,
      :unicorn_port => port
    })
  end

  nginx_site "#{app_name}.conf"

  port += 100
end
