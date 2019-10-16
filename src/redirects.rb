
def computeRedirect(uri, redirect_file)
	redirs = []
	rep = "$1"
	new_uri = nil
	matches = nil

	raw = File.open(redirect_file,"r").read.split("\n").map{|i| i.split}
	
	raw.each{|i| 
		h = {}
		h["status"] = i[0].to_i; 
		h["from"] = i[1]; 
		h["to"] = i[2];
		redirs.push h
	}

	redirs.each{|i|
		matches = /#{i["from"]}/.match uri
		if !matches.nil?
			new_uri = i["to"]
			m = matches[1..-1].reverse
			while new_uri.include? rep do
				new_uri.gsub!(rep, m.pop)
				rep.succ!
			end
		end
	}
	
	return nil if new_uri.nil?

	# Initialize a response and return that otherwise

	return new_uri
end

if __FILE__ == $0
	puts computeRedirect("a/mercury/b", "redirects.conf")
end
