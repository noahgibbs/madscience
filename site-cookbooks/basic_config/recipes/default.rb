#
# Cookbook Name:: basic_config
# Recipe:: default
#

# Your application(s) shouldn't run as root.
# Each should have a username assigned to it.
app_user = "www"

# Set up app-specific user, group and home directory
user app_user
group app_user
directory "/home/#{app_user}" do
  owner app_user
  group app_user
  mode "0755"
end

