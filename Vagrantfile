# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
MADSCIENCE_MINIMUM_GEM_VERSION = "0.0.25"

require_relative "config/madscience_config.rb"
require_relative "config/vagrant_deps.rb"

# Here's a list of environment variables to unset when getting a clean
# environment from inside Vagrant. Based on Vagrant::Util::Env.with_clean_env
UNSET_VARS = %w(_ORIGINAL_GEM_PATH GEM_PATH GEM_HOME GEM_ROOT
                BUNDLE_BIN_PATH BUNDLE_GEMFILE RUBYLIB RUBYOPT
                RUBY_ENGINE RUBY_ROOT RUBY_VERSION)

VagrantDeps.check_cloned_by
# Plugin list from madscience_gem. All versions exact.
VagrantDeps.check_plugins([
  { 'name' => 'vagrant-omnibus', 'version' => '1.4.1' },
  { 'name' => 'vagrant-librarian-chef', 'version' => '0.2.1' },
  { 'name' => 'vagrant-aws', 'version' => '0.6.0' },
  { 'name' => 'vagrant-digitalocean', 'version' => '0.7.3' },
  { 'name' => 'vagrant-linode', 'version' => '0.1.1' },
  { 'name' => 'vagrant-host-shell', 'version' => '0.0.4' },
])

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

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

  # Locate this user's SSH key
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
  config.omnibus.chef_version = "11.18.6"

  # Files under nodes/*.json.erb are nodes (VMs). For a multi-machine
  # setup, using more than one such file.
  chef_json_by_vm = get_json_by_vm
  home_dir = ENV['HOME'] || ENV['userprofile']
  creds_dir = File.join(home_dir, '.deploy_credentials')
  private_prov_key_path = File.join(creds_dir, 'id_rsa_provisioning_4096')

  config.vm.provider :aws do |provider, override|
    override.vm.box = 'dummy'
    override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
    override.ssh.username = "ubuntu"
    # TODO: FIX THIS VM!
    override.ssh.private_key_path = private_prov_key_path

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
    override.ssh.private_key_path = private_prov_key_path
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

  config.vm.provider :linode do |provider, override|
    override.ssh.private_key_path = private_prov_key_path
    override.vm.box = 'linode'
    override.vm.box_url = "https://github.com/displague/vagrant-linode/raw/master/box/linode.box"

    raise "Can't find linode.json in #{creds_dir}! Set one up first!" unless File.exist? File.join(creds_dir, "linode.json")
    ln_options = JSON.parse File.read File.join(creds_dir, "linode.json")

    ln_options.each do |key, value|
      next if key[0] == "#"  # Skip JSON 'comments'

      # Getting an error on this send? You may have set a property in the JSON
      # that doesn't exist.  See
      # https://github.com/displague/vagrant-linode, section "Supported
      # Configuration Attributes", for a list of current valid properties.
      provider.send("#{key}=", value)
    end
  end if File.exist?(File.join(creds_dir, 'linode.json'))

  chef_json_by_vm.keys.each do |vagrant_hostname|
    chef_json = chef_json_by_vm[vagrant_hostname]

    config.vm.define vagrant_hostname do |vagrant|
      vagrant.vm.hostname = vagrant_hostname

      # Note: port-forwarding doesn't usually work for real providers like AWS, Digital Ocean
      # and Linode.
      #config.vm.network "forwarded_port", guest: 80, host: 4321
      (chef_json['forwarded_ports'] || {}).each do |guest, host|
        next if guest.is_a?(String) && guest[0] == "#"  # Allow JSON comments
        config.vm.network "forwarded_port", guest: guest.to_i, host: host.to_i
      end

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

        # Turns out 'run_list' is basically a special keyword in Chef. Have to
        # use a different name to pass it in as node data.
        run_list = chef_json.delete 'run_list'
        chef_json['madscience_run_list'] = run_list
        chef.json = chef_json.dup  # Don't just assign, var changes in loop
        chef.run_list = run_list
      end

      config.vm.provision :host_shell do |shell|
        rails_apps = (chef_json["ruby_apps"] || {}).keys
        # Combination of clean env, bundle exec and subshell taken from mfenner's vagrant-capistrano-push plugin.
        # Plus use a login subshell to make sure rvm is all set up.
        app_lines = rails_apps.map { |app| "echo Deploying #{app} on #{vagrant_hostname}...\nbash -l -c \"INSTALL_APP=#{app} INSTALL_HOST=#{vagrant_hostname} bundle exec cap production deploy\"" }.join("\n")
        shell.inline = <<-SCRIPT_START + app_lines
    set -e
    unset -v #{UNSET_VARS.join " "}
    bundle
        SCRIPT_START
      end
    end
  end

  # We want to define a "vagrant push" to install only apps in addition to
  # running Capistrano when provisioning. That allows the app install
  # to happen alone, which is much faster than a full Chef run.
  # Can't run capistrano under Bundler -- it's not in Vagrant's set of gems.
  # Can't use mfenner's capistrano-push plugin for Vagrant, it only pushes one app.
  # So instead, we make a bash script that unsets Ruby-, Gem- and Bundler-related
  # environment variables, then pushes everything.
  config.push.define "local-exec" do |push|
    # Combination of clean env, bundle exec and subshell taken from mfenner's vagrant-capistrano-push plugin.
    # Plus use a login subshell to make sure rvm is all set up.
    script_start = <<-SCRIPT_START
      set -e
      unset -v #{UNSET_VARS.join " "}
      bundle
    SCRIPT_START

    app_lines = [ script_start ]

    vagrant_vms = chef_json_by_vm.keys
    vagrant_vms.each do |vm_name|
      chef_json = chef_json_by_vm[vm_name]
      rails_apps = (chef_json["ruby_apps"] || {}).keys

      app_lines += rails_apps.flat_map do |app|
        [ "echo Deploying #{app} on #{vm_name}...",
          "bash -l -c \"INSTALL_APP=#{app} INSTALL_HOST=#{vm_name} bundle exec cap production deploy\""
        ]
      end
    end

    push.inline = app_lines.join "\n"
  end
end
