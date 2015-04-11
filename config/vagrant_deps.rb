module VagrantDeps
  def self.check_cloned_by
    cloned_by = File.join(File.dirname(__FILE__), ".cloned_by")
    if File.exist?(cloned_by)
      first_line = File.read(cloned_by).split("\n")[0] || ""
      ver = first_line.scan(/\d+\.\d+\.\d+/)[0]
      if !ver || ver < MADSCIENCE_MINIMUM_GEM_VERSION
        puts "Warning: make sure you've set up this machine with at least MadScience #{MADSCIENCE_MINIMUM_GEM_VERSION}!"
      end
    else
      puts "Warning: no .cloned_by file, can't determine MadScience gem version!"
    end
  end

  def self.check_plugins(plugins_by_version)
    plugins_by_version.each do |p|
      unless Vagrant.has_plugin?(p["name"])
        STDERR.puts "Plugins are supposed to be handled by madscience_gem, but somehow they weren't. Not good."
        raise "Vagrant has no #{p["name"]} plugin! Run: vagrant plugin install #{p["name"]} --plugin-version #{p["version"]}"
      end
    end
  end
end
