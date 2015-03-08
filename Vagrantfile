# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require_relative "config/madscience_config.rb"

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
    # In this case, we want more than 1GB because it's often impossible to
    # compile Ruby 2.0.0+ with 1GB of memory.
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Use this specific, not-default-for-Vagrant Chef version
  # via the vagrant-omnibus plugin
  config.omnibus.chef_version = "12.0.3"

  # Files under nodes/*.json.erb are nodes (VMs). For a multi-machine
  # setup, using more than one such file.
  chef_json_by_vm = get_chef_json_by_vm

  # We want to define a "vagrant push" to install only apps in addition to
  # running Capistrano when provisioning. That allows the app install
  # to happen alone, which is much faster than a full Chef run.
  # Can't run capistrano under Bundler -- it's not in Vagrant's set of gems.
  # Can't use mfenner's capistrano-push plugin for Vagrant, it only pushes one app.
  # So instead, we make a bash script that unsets Ruby-, Gem- and Bundler-related
  # environment variables, then pushes everything.
  ["digital_ocean", "aws", "linode", "development"].each do |host_provider|
    config.push.define(host_provider, strategy: "local-exec") do |push|
      rails_apps = chef_json["ruby_apps"].keys
      # Combination of clean env, bundle exec and subshell taken from mfenner's vagrant-capistrano-push plugin.
      # Plus use a login subshell to make sure rvm is all set up.
      app_lines = rails_apps.map { |app| "echo Deploying #{app}...\nbash -l -c \"INSTALL_APP=#{app} bundle exec cap production deploy\"" }.join("\n")
      push.inline = <<-SCRIPT_START + app_lines
# List of unset variables from Vagrant::Util::Env.with_clean_env
unset -v _ORIGINAL_GEM_PATH GEM_PATH GEM_HOME GEM_ROOT BUNDLE_BIN_PATH BUNDLE_GEMFILE RUBYLIB RUBYOPT RUBY_ENGINE RUBY_ROOT RUBY_VERSION
      SCRIPT_START
    end
  end

  config.vm.provider :aws do |provider, override|
    override.vm.box = 'dummy'
    override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = File.join creds_dir, "id_rsa_provisioning_4096"

    provider.ami = 'ami-37eab407' # Default AMI
    raise "Can't find aws.json in #{creds_dir}! Set one up first!" unless File.exist? File.join(creds_dir, "aws.json")
    aws_options = JSON.parse File.read File.join(creds_dir, "aws.json")
    aws_options.each do |key, value|
      next if key[0] == "#"  # Skip JSON 'comments'

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

    chef.json = chef_json
    chef.run_list = chef_json['run_list']
  end

  config.vm.provision :host_shell do |shell|
    rails_apps = chef_json["ruby_apps"].keys
    # Combination of clean env, bundle exec and subshell taken from mfenner's vagrant-capistrano-push plugin.
    # Plus use a login subshell to make sure rvm is all set up.
    app_lines = rails_apps.map { |app| "echo Deploying #{app}...\nbash -l -c \"INSTALL_APP=#{app} bundle exec cap production deploy\"" }.join("\n")
    shell.inline = <<-SCRIPT_START + app_lines
#List of unset variables from Vagrant::Util::Env.with_clean_env
unset -v _ORIGINAL_GEM_PATH GEM_PATH GEM_HOME GEM_ROOT BUNDLE_BIN_PATH BUNDLE_GEMFILE RUBYLIB RUBYOPT RUBY_ENGINE RUBY_ROOT RUBY_VERSION
    SCRIPT_START
  end
end
