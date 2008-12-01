# Provides application-wide configuration settings
class AppConfig
  # Method missing will return a nil
  def self.method_missing(meth)
    nil
  end

  # Method missing will return a nil
  def method_missing(meth)
    nil
  end

  # Loads the configuration YAML file
  def self.load
    # Get the file
    config_file = File.join(RAILS_ROOT, "config", "application.yml")

    # See if it's there
    if File.exists?(config_file)
      # Load the configuration file for the current environment
      @@config = YAML.load(File.read(config_file))[RAILS_ENV]

      # Loop over all the keys
      @@config.keys.each do |key|
        # Make it accessible
        cattr_accessor key

        # Set the value
        send("#{key}=", @@config[key])
      end
    end
  end
end
