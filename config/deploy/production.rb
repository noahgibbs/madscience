# First, get host settings

# Parse output of ssh-config. Example:
# Host default
#   HostName 104.131.251.227
#   User root
#   Port 22
#   UserKnownHostsFile /dev/null
#   StrictHostKeyChecking no
#   PasswordAuthentication no
#   IdentityFile /Users/noah/.deploy_credentials/id_rsa_provisioning_4096
#   IdentitiesOnly yes
#   LogLevel FATAL
#   ForwardAgent yes

ssh_conf = `vagrant ssh-config #{$install_host}`
ssh_opts = {}
ssh_conf.split("\n").map(&:strip).each { |line| key, val = line.split(/\s+/, 2); ssh_opts[key] = val }

home_dir = ENV['HOME'] || ENV['userdir'] || "/home/#{ENV['USER']}"
creds_dir = File.join home_dir, ".deploy_credentials"

app_user = $app_data['user'] || 'www'

server ssh_opts['HostName'],
  user: app_user,
  roles: %w{web app db},
  ssh_options: {
    #user: 'user_name', # overrides user setting above
    keys: [ File.join(creds_dir, "id_rsa_deploy_4096") ],
    forward_agent: true,
    auth_methods: %w(publickey),
    port: ssh_opts['Port'],
    paranoid: false,  # Unfortunately, real hosting services often reassign IPs
    # password: 'please use only keys'
  }

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

#role :app, %w{deploy@example.com}
#role :web, %w{deploy@example.com}
#role :db,  %w{deploy@example.com}


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

#server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
