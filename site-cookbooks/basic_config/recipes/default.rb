#
# Cookbook Name:: basic_config
# Recipe:: default
#

# Your application(s) shouldn't run as root.
# Each should have a username assigned to it.

node["users"].each do |app_user, user_data|
  # Set up app-specific user, group and home directory
  user app_user do
    shell "/bin/bash"
    #password "$1$yN53x/Fr$HZhgHSrSrwQmu/AV1V/tG."  # Hash of "AppUserPassword"
  end

  group app_user
  directory "/home/#{app_user}" do
    owner app_user
    group app_user
    mode "0755"
  end

  # Put reasonable files in app-user directory so you can
  # log in and act as that user.
  template "/home/#{app_user}/.bashrc" do
    source "app_user_bash_rc.erb"
    owner app_user
    group app_user
    mode "0744"
  end

  template "/home/#{app_user}/.bash_profile" do
    source "app_user_bash_profile.erb"
    owner app_user
    group app_user
    mode "0744"
  end
end

# This is a workaround for a nasty Chef bug that breaks the Postgres cookbook
# and must be executed before it.  See COOK-1406, which Chef thinks is fixed.
# I agree with other commenters that this bug still clearly affects Chef
# 12.0.3, alas.

fix = Chef::Util::FileEdit.new("/opt/chef/embedded/lib/ruby/2.1.0/x86_64-linux/rbconfig.rb")
fix.search_file_delete_line("^.*LIBPATHENV.*$")
fix.write_file

# And here's a workaround because Postgres needs this repo installed and
# "apt-get update" executed before it runs, but it doesn't call apt-get
# update. So we need to do it first.

apt_repository 'apt.postgresql.org' do
  uri 'http://apt.postgresql.org/pub/repos/apt'
  distribution "#{node['lsb']['codename']}-pgdg"
  components ['main', '9.3']
  key 'http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc'
  action :add
end

e = execute 'apt-get update' do
  action :nothing
end

e.run_action :run
