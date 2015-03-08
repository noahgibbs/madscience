# Parsing of configuration for RubyMadScience

require "erubis"
require "json"

def get_chef_json_by_vm
  json_files = Dir[File.join(File.dirname(__FILE__), "..", "nodes", "*.json.erb")]
  json_by_vm = {}

  json_files.each do |file|
    eruby = Erubis::Eruby.new File.read file

    chef_json = JSON.parse eruby.result({})
    raise "Can't read JSON file for MadScience node #{file}!" unless chef_json

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

    # Get VM name from filename
    vm_name = File.split(file)[-1].split(".")[0].gsub("_", "-")
    json_by_vm[vm_name] = chef_json
  end

  json_by_vm
end
