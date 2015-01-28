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
  ssh_key_file = File.exist?(File.join(ssh_dir, "id_dsa")) ?
    File.join(ssh_dir, "id_dsa") :
      (File.exist?(File.join(ssh_dir, "id_rsa")) ?
       File.join(ssh_dir, "id_rsa") : nil)
  raise "No SSH key file found under home dir in .ssh/id_[rd]sa!" unless ssh_key_file

  # Configure a preferred private key, not the well-known insecure Vagrant key
  # See: https://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
  #      http://stackoverflow.com/questions/14715678/vagrant-insecure-by-default/14719184

  #config.ssh.private_key_path = [ssh_key_file]
  # Need insecure to bootstrap, but we blow away the vagrant user's
  # authorized keys below (root, too, but in the Chef cookbook.)
  config.ssh.private_key_path = [ssh_key_file,File.join(home_dir, ".vagrant.d", "insecure_private_key")]

  # Allow secure key to work, blow away insecure key.
  # Still have to change vagrant and root passwords via Chef, though!
  config.vm.provision "shell", inline: <<-SCRIPT
    # TODO: add provisioning key to authorized_keys file
    printf "%s\n" "#{File.read(ssh_key_file + ".pub")}" > /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
  SCRIPT

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
    #vb.customize ["modifyvm", :id, "--memory", "1024"]
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
  chef_json['ssh_public_provisioning_key'] = File.read File.join(creds_dir, 'id_rsa_provisioning_4096.pub')
  chef_json['ssh_private_provisioning_key'] = File.read File.join(creds_dir, 'id_rsa_provisioning_4096')
  chef_json['ssh_public_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096.pub')
  chef_json['ssh_private_deploy_key'] = File.read File.join(creds_dir, 'id_rsa_deploy_4096')
  chef_json['authorized_keys'] = File.read File.join(creds_dir, 'authorized_keys')

  config.vm.provider :digital_ocean do |provider, override|
    # Above, we use this user's main key for the Vagrant user.
    # That's not necessarily as secure as we want for off-machine use.
    # It means you can't directly SSH in without specifying an SSH
    # key for off-machine use... Which is, honestly, probably a really
    # good idea.
    override.ssh.private_key_path = File.join home_dir, '.deploy_credentials', 'digital_ocean_ssh_key'
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master"

    provider.token = File.read(File.join(creds_dir, 'digital_ocean_token')).strip
    provider.image = 'ubuntu-14-04-x64'
    provider.region = 'nyc2'
    provider.size = '1gb'
    # provider.setup false  # Can we do this?
  end if File.exist?(File.join(creds_dir, 'digital_ocean_token'))

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
