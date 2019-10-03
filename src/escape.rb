class String
	def escape
		escapes = {":"=>"%3A", "/"=>"%2F", "?"=>"%3F", "#"=>"%23", "["=>"%5B", "]"=>"%5D", "@"=>"%40", "!"=>"%21", "$"=>"%24", "&"=>"%26", "\""=>"%27", "("=>"%28", ")"=>"%29", "*"=>"%2A", "+"=>"%2B", ","=>"%2C", ";"=>"%3B", "="=>"%3D", " "=>"%20"}
		str = ""
		str.replace self
		
		str.sub!("%","%25")
		escapes.each{ |i,j| str.sub!(i,j) }
		return str
	end
	
	def remEscapes
		escs = {"%3A"=>":", "%2F"=>"/", "%3F"=>"?", "%23"=>"#", "%5B"=>"[", "%5D"=>"]", "%40"=>"@", "%21"=>"!", "%24"=>"$", "%26"=>"&", "%27"=>"\"", "%28"=>"(", "%29"=>")", "%2A"=>"*", "%2B"=>"+", "%2C"=>",", "%3B"=>";", "%3D"=>"=", "%25"=>"%", "%20"=>" "}
		str = ""
		str.replace self
	
		escs.each { |i,j| str.sub!(i,j) }
		return str
	end
end

if __FILE__ == $0
	bluh = ";@#/?[]():%"

	puts bluh
	puts bluh.escape
	puts bluh.remEscapes
end
