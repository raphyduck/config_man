require "simple_config_man/version"
require 'simple_speaker'

@speaker = SimpleSpeaker::Speaker.new

module SimpleConfigMan
  def self.configure_node(node, name = '', current = nil)
    if name == '' || @speaker.ask_if_needed("Do you want to configure #{name}? (y/n)", 0, 'y') == 'y'
      node.each do |k, v|
        curr_v = current ? current[k] : nil
        if v.is_a?(Hash)
          node[k] = self.configure_node(v, name + ' ' + k, curr_v)
        elsif ['password','client_secret'].include?(k)
          node[k] = STDIN.getpass("What is your #{name} #{k}? ")
        else
          @speaker.speak_up "What is your #{name} #{k}? [#{curr_v}] "
          node[k] = STDIN.gets.strip
        end
        node[k] = curr_v if (node[k].nil? || node[k] == '') && !v.is_a?(Hash)
      end
    else
      node = current
    end
    node
  end

  def self.load_settings(config_dir, config_file, config_example)
    Dir.mkdir(config_dir) unless File.exist?(config_dir)
    unless File.exist?(config_file)
      FileUtils.copy config_example, config_file
      self.reconfigure(config_file, config_example)
    end
    YAML.load_file(config_file)
  end

  def self.reconfigure(config_file, config_example)
    config = YAML.load_file(config_file)
    default_config = YAML.load_file(config_example)
    #Let's set the first config
    @speaker.speak_up 'The configuration file needs to be initialized.'
    config = self.configure_node(default_config, '', config)
    @speaker.speak_up 'All set!'
    File.write(config_file, YAML.dump(config))
  end
end
