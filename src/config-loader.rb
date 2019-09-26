require 'yaml'

def load_config(fname)
	file = File.open(fname, "r")
	config = YAML.load(file.read)
	
	#Handles non-uppercase method names in config file
	config["allowed-methods"].map!(&:upcase) if config.key?("allowed-methods")

	return config
end

# Ghetto unit test
if __FILE__ == $0
	cfg = load_config("config.yml")
	cfg["allowed-methods"].each { |i| puts i }
end
