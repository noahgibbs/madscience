# Parsing of configuration for RubyMadScience

def get_chef_json_by_vm
  json_erb_path = File.join(File.dirname(__FILE__), "..", "nodes", "all_nodes.json.erb")
  eruby = Erubis::Eruby.new File.read(json_erb_path)

  chef_json = JSON.parse eruby.result({})
  raise "Can't read JSON file for vagrant Chef node!" unless chef_json

  home_dir = ENV['HOME'] || ENV['userprofile']
  creds_dir = File.join(home_dir, '.deploy_credentials')

  # Read local credentials and pass them to Chef
  # We need to pass in the private deploy key so that Capistrano can clone your Git repo from the host
  chef_json['ssh_public_provisioning_key'] = File.read File.join(creds_dir, 'id_rsa_provisioning_4096.pub')
  chef_json['ssh_public_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096.pub')
  chef_json['ssh_private_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096')

  # For authorized keys, let in anybody you specified in ~/.deploy_credentials/authorized_keys, plus the
  # provisioning and deploy keys.
  chef_json['authorized_keys'] = [
    File.read(File.join(creds_dir, 'authorized_keys')),
    chef_json['ssh_public_deploy_key'],
    chef_json['ssh_public_provisioning_key'] ].join("\n")

  { "all_nodes" => chef_json }
end
