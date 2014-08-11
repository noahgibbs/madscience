# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'rails-devise-pundit'
set :repo_url, 'https://github.com/noahgibbs/rails-devise-pundit.git'

set :rails_env, 'production'

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
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

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
          #password:

        development:
          database: #{fetch(:application)}_development
          <<: *base

        test:
          database: #{fetch(:application)}_test
          <<: *base

        production:
          database: #{fetch(:application)}_production
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
  before "deploy:updated", "db:symlink"
end
