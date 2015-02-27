# config valid only for Capistrano 3.1
lock '3.2.1'

has_mysql = true if $cap_json["run_list"].any? { |s| s["mysql"] }
has_postgresql = true if $cap_json["run_list"].any? { |s| s["postgresql"] }

raise "Can't use both MySQL and Postgres!" if has_mysql && has_postgresql
raise "Must use one of MySQL or Postgres!" unless has_mysql || has_postgresql

set :db_driver, has_mysql ? "mysql" : "postgresql"

set :db_root_password, $cap_json[fetch(:db_driver)]["server_root_password"]
set :default_env, $app_data["env_vars"] || {}

set :application, ENV['INSTALL_APP']
set :app_db_name, $app_data["db_name"] || (ENV['INSTALL_APP'].gsub("-", "_") + "_production")
set :repo_url, $app_data["git"]

# Set to the app's Ruby version
set :rvm_ruby_version, '2.0.0-p598'  # Where does this default go? Also, make it settable per-app

$app_data["env_vars"] ||= {}
set :rails_env, $app_data["env_vars"]["RAILS_ENV"] || $app_data["env_vars"]["RACK_ENV"] || 'production'

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
          adapter: #{fetch(:db_driver) == "mysql" ? "mysql2" : "postgresql" }
          encoding: #{has_mysql ? "utf8" : "unicode"}
          #{has_mysql ? "reconnect: false" : ""}
          pool: 5
          host: localhost
          username: #{has_mysql ? "root" : "postgres"}
          password: #{fetch(:db_root_password)}
          timeout: 5000

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

  # Can we find a way to do this with linked_files? The hard part is that tasks like
  # migration and asset compilation seem to happen before the files are linked.
  namespace :log do
    task :symlink do
      on roles(:all) do |host|
        execute :ln, "-nfs", "#{shared_path}/log", "#{release_path}/log"
      end
    end
  end

  before "deploy:starting", "db:configure"
  before "deploy:updated", "db:symlink"  # Why not linked_files? Because that doesn't happen at the right time.
  before "deploy:updated", "log:symlink"  # Why not linked_files? Because that doesn't happen at the right time.
end
