require "simple_config_man/version"
require 'simple_speaker'

module SimpleConfigMan
  def self.configure_node(node, name = '', current = nil, remove_existing = 0)
    if name == '' || speaker.ask_if_needed("Do you want to configure #{name}? (y/n)", 0, 'y') == 'y'
      node.each do |k, v|
        curr_v = current ? current[k] : nil
        if v.is_a?(Hash)
          node[k] = self.configure_node(v, name + ' ' + k, curr_v, remove_existing)
        elsif ['password','client_secret'].include?(k)
          node[k] = STDIN.getpass("What is your #{name} #{k}? ")
        else
          speaker.speak_up "What is your #{name} #{k}? [#{curr_v}] "
          node[k] = STDIN.gets.strip
        end
        node[k] = curr_v if (node[k].nil? || node[k] == '') && !v.is_a?(Hash) && remove_existing == 0
      end
    else
      node = remove_existing > 0 ? nil : current
    end
    node
  end

  def self.load_settings(config_dir, config_file, config_example)
    Dir.mkdir(config_dir) unless File.exist?(config_dir)
    unless File.exist?(config_file)
      self.reconfigure(config_file, config_example)
    end
    YAML.load_file(config_file)
  end

  def self.reconfigure(config_file, config_example)
    remove_existing = 0
    begin
      config = YAML.load_file(config_file)
    rescue
      remove_existing = 1
      config = YAML.load_file(config_example)
    end
    default_config = YAML.load_file(config_example)
    #Let's set the first config
    speaker.speak_up 'The configuration file needs to be initialized.'
    config = self.configure_node(default_config, '', config, remove_existing)
    speaker.speak_up 'All set!'
    File.write(config_file, YAML.dump(config))
  end

  def self.speaker
    @speaker ||= SimpleSpeaker::Speaker.new
  end
end
