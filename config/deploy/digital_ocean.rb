# First, get Digital Ocean settings

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

conf = `vagrant ssh-config`
ssh_opts = {}
conf.split("\n").map(&:strip).split(" ", 2).each { |key, val| ssh_opts[key] = val }

server conf['HostName'],
  user: 'www',
  roles: %w{web app db},
  ssh_options: {
    #user: 'user_name', # overrides user setting above
    keys: [ File.join(home_dir, ".deploy_credentials", "id_rsa_deploy_4096") ],
    forward_agent: true,
    auth_methods: %w(publickey),
    port: 2222,
    # password: 'please use keys'
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
