require 'yaml'

def load_config(fname)
	begin
		file = File.open(fname, "r")
		config = YAML.load(file.read)
	
		#Handles non-uppercase method names in config file
		config["allowed-methods"].map!(&:upcase) if config.key?("allowed-methods")
		config["extant-methods"].map!(&:upcase) if config.key?("extant-methods")
		loadRedirects(config)

		return config
	rescue Errno::ENOENT
		abort "config file \'#{fname}\' doesn't exist"
	end
end

def loadRedirects(config)
	raw = File.open(config["redirect-file"],"r").read.split("\n").map{|i| i.split}

	config.store("redirects",[])
	
	raw.each{|i|
		#puts i
		h = {}
		h["status"] = i[0].to_i
		h["from"] = i[1]
		h["to"] = i[2]
		config["redirects"].push h
	}
end

# Ghetto unit test
if __FILE__ == $0
	cfg = load_config("config.yml")
	puts cfg["host"]
	puts cfg["port"]
	cfg["allowed-methods"].each { |i| puts i + "|" }
	cfg["extant-methods"].each{ |i| puts i + "|" }
	puts cfg["web-root"]
	puts cfg["default-page"]
	puts cfg["timeout"]

	cfg2 = load_config("filethatdoesn'texist.filename")
	puts "Making sure exception kills the program"
end
