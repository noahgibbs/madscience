#
# Cookbook Name:: basic_config
# Recipe:: default
#

# Your application(s) shouldn't run as root.
# Each should have a username assigned to it.

# Allow Chef to set passwords
package "libshadow-ruby1.8"

node["users"].each do |app_user, user_data|
  # Set up app-specific user, group and home directory
  user app_user do
    shell "/bin/bash"
    password "$1$yN53x/Fr$HZhgHSrSrwQmu/AV1V/tG."  # Hash of "AppUserPassword"
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
