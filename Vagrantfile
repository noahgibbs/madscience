# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # This doesn't usually work for real providers like AWS, Digital Ocean
  # and Linode.
  config.vm.network "forwarded_port", guest: 80, host: 4321
  config.vm.network "forwarded_port", guest: 8800, host: 4322

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true

  # Workaround: avoids 'stdin: is not a tty' error.
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # First, locate this user's SSH key
  home_dir = ENV['HOME'] || ENV['userdir'] || "/home/#{ENV['USER']}"
  ssh_dir = File.join(home_dir, ".ssh")

  # Configure a preferred private key, not the well-known insecure Vagrant key
  # See: https://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
  #      http://stackoverflow.com/questions/14715678/vagrant-insecure-by-default/14719184

  # TODO: Check keys for non-Vagrant users in cookbook, any use of non-RDIAH keys?

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Don't boot with headless mode
    #vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # View the documentation for the provider you're using for more
  # information on available options.

  # Use this specific, not-default-for-Vagrant Chef version
  config.omnibus.chef_version = "11.12.8"

  # The file nodes/vagrant.json contains the Chef attributes,
  # plus a run_list.

  json_erb_path = File.join(File.dirname(__FILE__), "nodes", "all_nodes.json.erb")
  eruby = Erubis::Eruby.new File.read(json_erb_path)

  # TODO: add Vagrant-specific node file and merge it over top of all_nodes.json.erb
  chef_json = JSON.parse eruby.result({})
  raise "Can't read JSON file for vagrant Chef node!" unless chef_json

  # TODO: test on Windows
  home_dir = ENV['HOME'] || ENV['userprofile']
  creds_dir = File.join(home_dir, '.deploy_credentials')

  # Read local credentials and pass them to Chef
  # We need to pass in the private deploy key so that Capistrano can clone your Git repo from the host
  chef_json['ssh_public_provisioning_key'] = File.read File.join(creds_dir, 'id_rsa_provisioning_4096.pub')
  #chef_json['ssh_private_provisioning_key'] = File.read File.join(creds_dir, 'id_rsa_provisioning_4096')
  chef_json['ssh_public_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096.pub')
  chef_json['ssh_private_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096')

  # For authorized keys, let in anybody you specified in ~/.deploy_credentials/authorized_keys, plus the
  # provisioning and deploy keys.
  chef_json['authorized_keys'] = [
    File.read(File.join(creds_dir, 'authorized_keys')),
    chef_json['ssh_public_deploy_key'],
    chef_json['ssh_public_provisioning_key'] ].join("\n")

  # Can't run capistrano under Bundler -- it's not in Vagrant's set of gems.
  # Can't use mfenner's capistrano-push plugin for Vagrant, it only pushes one app.
  # So instead, we make a bash script that unsets Ruby-, Gem- and Bundler-related
  # environment variables, then pushes everything.
  ["digital_ocean", "aws", "linode", "development"].each do |host_provider|
    config.push.define(host_provider, strategy: "local-exec") do |push|
      rails_apps = chef_json["ruby_apps"].keys
      # Combination of clean env, bundle exec and subshell taken from mfenner's vagrant-capistrano-push plugin.
      # Plus use a login subshell to make sure rvm is all set up.
      app_lines = rails_apps.map { |app| "echo Deploying #{app}...\npwd\nenv\nbash -l -c \"INSTALL_APP=#{app} bundle exec cap #{host_provider} deploy\"" }.join("\n")
      push.inline = <<-SCRIPT_START + app_lines
# List of unset variables from Vagrant::Util::Env.with_clean_env
unset -v _ORIGINAL_GEM_PATH GEM_PATH GEM_HOME GEM_ROOT BUNDLE_BIN_PATH BUNDLE_GEMFILE RUBYLIB RUBYOPT RUBY_ENGINE RUBY_ROOT RUBY_VERSION
      SCRIPT_START
    end
  end

  config.vm.provider :aws do |provider, override|
    override.vm.box = 'dummy'
    override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

    provider.ami = 'ami-37eab407'
    raise "Can't find aws.json in #{creds_dir}! Set one up first!" unless File.exist? File.join(creds_dir, "aws.json")
    aws_options = JSON.parse File.read File.join(creds_dir, "aws.json")
    aws_options.each do |key, value|
      next if key[0] == "#"  # Skip JSON 'comments'

      # How do we detect that this is the provider actually being used right now?
      #if key == "access_key_id" && value == ""
      #  raise "Hey! You have to edit aws.json in #{creds_dir} and set up your AWS credentials first!"
      #end

      # Getting an error on the following line? You may have set a property in the JSON
      # that doesn't exist.  See https://github.com/mitchellh/vagrant-aws,
      # section "Configuration", for a list of current valid properties.
      provider.send("#{key}=", value)
    end
  end

  config.vm.provider :digital_ocean do |provider, override|
    override.ssh.private_key_path = File.join creds_dir, "id_rsa_provisioning_4096"
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master"

    raise "Can't find digital_ocean.json in #{creds_dir}! Set one up first!" unless File.exist? File.join(creds_dir, "digital_ocean.json")
    do_options = JSON.parse File.read File.join(creds_dir, "digital_ocean.json")

    do_options.each do |key, value|
      next if key[0] == "#"  # Skip JSON 'comments'

      # Getting an error on this send? You may have set a property in the JSON
      # that doesn't exist.  See
      # https://github.com/smdahlen/vagrant-digitalocean, section "Supported
      # Configuration Attributes", for a list of current valid properties.
      provider.send("#{key}=", value)
    end
  end if File.exist?(File.join(creds_dir, 'digital_ocean.json'))

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = ["site-cookbooks", "cookbooks"]
    chef.roles_path = "roles"
    chef.data_bags_path = "data_bags"
    chef.provisioning_path = "/tmp/vagrant-chef"

    # WORKAROUND: This is to prevent a nasty SSL and HTTP warning
    chef.custom_config_path = "Vagrantfile.chef"

    # You may also specify custom JSON attributes:
    run_list = chef_json.delete 'run_list'
    chef.json = chef_json
    chef.run_list = run_list
  end
end
