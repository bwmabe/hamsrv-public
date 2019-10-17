require_relative 'config-loader.rb'
require_relative 'req-res.rb'

def computeRedirect(uri, config)
	redirs = config["redirects"]
	rep = "$1"
	new_uri = nil
	matches = nil
	res = Response.new

	# raw = File.open(redirect_file,"r").read.split("\n").map{|i| i.split}
	
	redirs.each{|i|
		matches = /#{i["from"]}/.match uri
		if !matches.nil?
			new_uri = i["to"]
			m = matches[1..-1].reverse
			while new_uri.include? rep do
				new_uri.gsub!(rep, m.pop)
				rep.succ!
			end
			ret = {}
			ret["status"] = i["status"]
			ret["uri"] = new_uri
			return ret
		end
	}
	
	return nil if new_uri.nil?

	# Initialize a response and return that otherwise

	return res
end

if __FILE__ == $0
	cfg = load_config("config.yml")
	
	#puts cfg["redirects"]

	a =computeRedirect("a/mercury/b", cfg)
	puts a["uri"] + " " + a["status"].to_s
end
