# config valid only for Capistrano 3.1
lock '3.2.1'

# We want to share app data between Chef and Capistrano. So load
# it here from the appropriate .json.erb file.
require "erubis"
require "json"
json_erb_path = File.join(File.dirname(__FILE__), "..", "nodes", "all_nodes.json.erb")
eruby = Erubis::Eruby.new File.read(json_erb_path)

cap_json = JSON.parse eruby.result({})
raise "Can't read JSON file for vagrant Capistrano node!" unless cap_json

# We must specify which application to install. There could be multiple.
ENV['INSTALL_APP'] ||= cap_json["ruby_apps"].keys.first

raise "You must specify an INSTALL_APP variable or just have one app!" unless ENV['INSTALL_APP']
app = cap_json["ruby_apps"][ENV['INSTALL_APP']]
raise "Can't find app #{ENV['INSTALL_APP'].inspect} under ruby_apps in JSON!" unless app

set :mysql_server_root_password, cap_json["mysql"]["server_root_password"]
set :default_env, app["env_vars"] || {}

set :application, ENV['INSTALL_APP']
set :app_db_name, app["db_name"] || (ENV['INSTALL_APP'].gsub("-", "_") + "_production")
set :repo_url, app["git"]
# Want to use a protected Git URL, such as a GitHub SSH URL? You'll need to add the
# SSH key to the appropriate user -- or use agent forwarding and have permissions locally.

set :rails_env, app["env_vars"]["RAILS_ENV"] || app["env_vars"]["RACK_ENV"] || 'production'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 10

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  namespace :db do
    desc "Create database yaml in shared path"
    task :configure do
      #set :database_username, 'root'
      #set :database_password do
      #  Capistrano::CLI.password_prompt "Database Password: "
      #end

      db_config = <<-EOF
        base: &base
          adapter: mysql2
          encoding: utf8
          reconnect: false
          pool: 5
          username: root
          password: #{fetch(:mysql_server_root_password)}

        production:
          database: #{fetch(:app_db_name)}
          <<: *base
      EOF
      db_config_io = StringIO.new(db_config)

      on roles(:all) do |host|
        execute :mkdir, "-p", "#{shared_path}/config"
        upload! db_config_io, "#{shared_path}/config/database.yml"
      end
    end

    desc "Make symlink for database yaml"
    task :symlink do
      on roles(:all) do |host|
        execute :ln, "-nfs", "#{shared_path}/config/database.yml", "#{release_path}/config/database.yml"
      end
    end
  end
  before "deploy:starting", "db:configure"
  before "deploy:updated", "db:symlink"  # Why not linked_files? Because that doesn't happen at the right time.
end
