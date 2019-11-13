require 'yaml'
require 'find'

def load_config(fname)
	begin
		file = File.open(fname, "r")
		config = YAML.load(file.read)
	
		#Handles non-uppercase method names in config file
		config["allowed-methods"].map!(&:upcase) if config.key?("allowed-methods")
		config["extant-methods"].map!(&:upcase) if config.key?("extant-methods")
		loadRedirects(config)

		loadProtected(config)

		return config
	rescue Errno::ENOENT
		abort "config file \'#{fname}\' doesn't exist"
	end
end

def loadProtected(config)
	config.store("protected",[])
	dirs = []
	temp = {}

	Find.find(config["web-root"]) do |i|
		dirs.push(i.split(config["web-root"])[1].split("/" + config["access-file"])[0]) if i.include?(config["access-file"])
	end

	dirs.each{ |i|
		temp = {}
		temp["dir"] = i
		f = File.open("./" + config["web-root"] + i + "/" + config["access-file"], "r").read
		f = f.split("\n").map{|j|
			j if j[0] != "#"
		}.compact
		temp["users"] = []
		f.each{|j|
			if j.include?("=")
				a = j.split("=",2)
				temp[a[0]] = a[1].tr("\"","")
			end

			if j.include?(":")
				u = {}
				a = j.split(":")
				u["name"] = a[0]
				if !a[2].nil?
					u["hash"] = a[2]
					u["realm"] = a[1]
				else
					u["hash"] = a[1]
				end
			end
			temp["users"].push(u)

		}
		temp["users"].compact!
		config["protected"].push(temp)
	}
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
	puts cfg["access-file"]
	puts cfg["nonce-key"]
	cfg["protected"].each{|i| puts i}

	cfg2 = load_config("filethatdoesn'texist.filename")
	puts "Making sure exception kills the program"
end
