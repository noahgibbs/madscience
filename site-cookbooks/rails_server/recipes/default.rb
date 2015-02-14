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
package "gawk" # This is from "rvm requirements" for Ubuntu

# SECURITY: change vagrant and root passwords to stop being "vagrant"
user "root" do
  password "*"  # Don't allow login via password, only SSH keys
end
user "vagrant" do
  password "*"  # Don't allow login via password, only SSH keys
end

# SECURITY: authorize only requested keys for root
directory "/root/.ssh" do
  owner "root"
  mode "0600"
end
file "/root/.ssh/authorized_keys" do
  owner "root"
  group "root"
  mode "0600"
  content node["authorized_keys"]
end
file "/root/.ssh/id_rsa_deploy.pub" do
  owner "root"
  group "root"
  mode "0600"
  content node["ssh_public_deploy_key"]
end
file "/root/.ssh/id_rsa_deploy" do
  owner "root"
  group "root"
  mode "0600"
  content node["ssh_private_deploy_key"]
end
file "/root/ssh_deploy_key_wrapper.sh" do
  owner "root"
  group "root"
  mode "0755"
  content "#!/bin/sh\nexec /usr/bin/ssh -i /root/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no \"$@\""
end

users = []
if node["users"].is_a?(Hash)
  users = node["users"].keys
elsif node["users"].is_a?(Array)
  users = node["users"].to_a
else
  raise "Unrecognized 'users' entry in JSON: #{users.inspect}!"
end

# Any unmentioned users from apps or sites should get created too.
add_users = ((node["ruby_apps"] || {}).values + (node["static_sites"] || {}).values).map { |h| h["user"] }.compact.uniq
users += add_users
users.uniq!

# Use RVM's user_install recipe. Seems to be no LWRP equivalent.
# That means setting attributes.
node.default["rvm"]["user_installs"] = users.map { |u| { 'user' => u } }
include_recipe "rvm::user_install"
include_recipe "runit"

# Using MySQL or Postgres?
has_mysql = node["madscience_run_list"].any? { |s| s["mysql"] }
has_postgres = node["madscience_run_list"].any? { |s| s["postgres"] }

raise "Can't use both Postgres and MySQL on one node!" if has_mysql && has_postgres

if has_mysql
  include_recipe "database::mysql"
elsif has_postgres
  include_recipe "database::postgres"
end

users.each do |app_user|
  # Install RVM and Ruby for each user

  ruby_version = "2.0.0-p598"  # TODO: get from JSON

  rvm_ruby ruby_version do
    user app_user
  end

  rvm_default_ruby ruby_version do
    user app_user
  end

  # Test RVM install
  rvm_shell 'echo ruby' do
    user app_user
    ruby_string ruby_version
    code 'echo My Ruby is `rvm current`!'  # Use bash backticks to return the current Ruby version
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
    mode "0600"
    content node['authorized_keys']
  end

  file "/home/#{app_user}/.ssh/id_rsa.pub" do
    owner app_user
    group app_user
    mode "0600"
    content node['ssh_public_deploy_key']
  end

  file "/home/#{app_user}/.ssh/id_rsa" do
    owner app_user
    group app_user
    mode "0600"
    content node['ssh_private_deploy_key']
  end

  file "/home/#{app_user}/ssh_deploy_key_wrapper.sh" do
    owner app_user
    group app_user
    mode "0755"
    content "#!/bin/sh\nexec /usr/bin/ssh -i /home/#{app_user}/.ssh/id_rsa -o StrictHostKeyChecking=no \"$@\""
  end

end

# Who owns the top-level deploy directory?
directory "/var/www" do
  owner "root"
  group "root"
  mode "0755"
end

# Who owns the top-level deploy directory?
directory "/var/www/static" do
  owner "root"
  group "root"
  mode "0755"
end

# Create databases for applications
(node["ruby_apps"] || []).each do |app_name, app_data|
  db_name = app_data["db_name"] || (app_name.gsub("-", "_") + "_production")
  if has_mysql
    mysql_database db_name do
      connection(
        :host     => 'localhost',
        :username => 'root',
        :password => node['mysql']['server_root_password']
      )
      action :create
    end
  elsif has_postgres
    postgres_database db_name do
      connection(
        :host     => 'localhost',
        :username => 'root',
        :password => node['postgresql']['server_root_password']
      )
      action :create
    end
  end

  (app_data["packages"] || []).each do |pkg|
    if pkg.is_a?(String)
      package pkg
    elsif pkg.respond_to?(:each) && pkg.size == 2
      package pkg[0] { version pkg[1] }
    else
      raise "Unrecognized package specification: #{pkg.inspect}!"
    end
  end
end

# Create application directories for Capistrano to deploy to
(node["ruby_apps"] || []).each do |app_name, app_data|
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

# Create NGinX configs for static sites
(node["static_sites"] || []).each do |site_name, site_data|
  site_dir = "/var/www/static/#{site_name}"

  directory site_dir do
    user site_data["user"] || "root"
    group site_data["user"] || "root"
    mode "0755"
  end

  git site_dir do
    repository site_data["git"]
    revision site_data["git_revision"] if site_data["git_revision"]
    user site_data["user"] || "root"

    # Use wrapper to set deploy key
    is_root = !site_data["user"] || site_data["user"] == "root"
    if is_root
      ssh_wrapper("/root/ssh_deploy_key_wrapper.sh")
    else
      ssh_wrapper("/home/#{site_data["user"]}/ssh_deploy_key_wrapper.sh")
    end
  end

  if site_data["root"]
    if site_data["root"][0] == "/"
      site_root = site_data["root"]
    else
      site_root = File.join site_dir, site_data["root"]
    end
  else
    site_root = site_dir
  end

  template "#{node['nginx']['dir']}/sites-available/#{site_name}-static.conf" do
    source "nginx-static-site.conf.erb"
    mode "0644"
    variables({
      :site_dir => site_dir,
      :site_name => site_name,
      :site_root => site_data["root"] || site_dir,
      :server_names => site_data["server_names"] ? [site_data["server_names"]].flatten : [],
      :redirect_hostnames => site_data["redirect_hostnames"] ? [site_data["redirect_hostnames"]].flatten : []
    })
  end

  nginx_site "#{site_name}-static.conf"
end

# Create services, run files and other runit and nginx infrastructure
port = 8800 # Assign consecutive Unicorn port ranges starting at 8800
(node["ruby_apps"] || []).each do |app_name, app_data|
  ruby_version = "ruby-2.0.0-p598" # TODO: Make settable per-app
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

  template "#{node['nginx']['dir']}/sites-available/#{app_name}-app.conf" do
    source "nginx-site.conf.erb"
    mode "0644"
    variables({:app_dir => vars[:app_dir],
      :app_name => app_name,
      :unicorn_port => port,
      :server_names => app_data["server_names"] ? [app_data["server_names"]].flatten : [],
      :redirect_hostnames => app_data["redirect_hostnames"] ? [app_data["redirect_hostnames"]].flatten : []
    })
  end

  nginx_site "#{app_name}-app.conf"

  port += 100
end
