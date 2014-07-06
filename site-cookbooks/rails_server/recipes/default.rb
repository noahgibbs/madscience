#
# Cookbook Name:: rails_server
# Recipe:: default
#

# First, apt-get update. We do that with the run_list in
# the Node JSON file.

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
# I don't use a Gemset here, but you could.
# If you do, use rvm_environment "ruby-2.0.0-p0@my_gemset"
rvm_default_ruby "2.0.0" do
  user app_user
end

# Test RVM install
rvm_shell 'echo ruby' do
  user app_user
  code 'echo My Ruby is `rvm current`!'
  returns [0]
end

#rvm_shell "migrate_rails_database" do
#  #ruby_string "1.8.7-p352@webapp"
#  user        app_user
#  group       app_user
#  cwd         "/srv/webapp/current"
#  code        %{bundle exec rake RAILS_ENV=production db:migrate}
#end
