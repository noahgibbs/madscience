#
# Cookbook Name:: rails_server
# Recipe:: default
#

# First, apt-get update. We do that with the run_list in
# the Node JSON file.

include_recipe 'apt'
include_recipe 'mysql::client'
include_recipe 'mysql::server'

# MySQL Config
# http://community.opscode.com/cookbooks/mysql
mysql_service 'default' do
  # version '5.6'
  allow_remote_root false
  server_root_password 'iloverandompasswords'
  action :create
end

mysql_client 'default'
