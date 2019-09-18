require 'yaml'

def load_config(fname)
	file = File.open(fname, "r")
	config = YAML.load(file.read)
	return config
end
