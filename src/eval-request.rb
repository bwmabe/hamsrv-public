require_relative "req-res"
require_relative "responses"
require_relative "config-loader"
require_relative "mime"

def evalReq(request, response, config)
	if __FILE__ == $0
		debug = true
		config["allowed-methods"].each { |i| puts i }
	end
	
	response.status = RESPONSES[200] 

	#check method
	if !config["allowed-methods"].include?(request.method)
		if !config["extant-methods"].include?(request.method)
			response.status = RESPONSES[400]
		elsif !["HEAD", "OPTIONS"].include?(request.method)
			response.status = RESPONSES[501]
		end
		
		return response
	end
	#puts "method good" if debug
	
	#check uri
	# - Make sure Host is declared if uri does not begin with http://

	# Don't even attempt to make sure that the URI is usable if it contains invalid chars
	#return RESPONSES[400] if !request.uri.include?("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&()*+,;=")
	#puts "URI is all allowed chars" if debug

	if !request.uri.include?("http")
		if !request.headers.key?('Host')
		# If host is not in URI; bad request if host is not in headers either
			response.status = RESPONSES[501]
		#response.addHeader("DBG", request.fullFname)
			return response
		end
	end
	
	#response.status = RESPONSES[505]; return response if request.version.split("/")[1].to_f > 1.1
	
	# Method switch goes here
	# assumes all previous checks passed
	
	# GET resource at uri to find content type
	ctype = "text/plain" #Fallback
	resource = ""
	
	response.addHeader("Content-Type", getMIME(request.fname))	

	begin
		puts request.fullFname if debug
		resource = File.new(request.fullFname, "r")
		body = resource.read
		response.addHeader("Content-Length", resource.size.to_s)
	rescue
		response.addHeader("Content-Type", ctype)
		response.status = RESPONSES[404]
		response.addHeader("DEBUG", request.fullFname)
		return response
	end

	case request.method
	when 'GET'
		# check if file exists
		# check if file readable
		response.body = body
	when 'HEAD'
		# do head things
		# shouldn't have to anything since everything is done above
		response.status = RESPONSES[200]
	when 'OPTIONS'
		# do options things
	when 'TRACE'
		# do trace things
		response.addHeader("Content-Type", "message/http")
		response.status = RESPONSES[200]
		
	end
	response.status = RESPONSES[200]
	return response
end

if __FILE__ == $0
	puts "Testing eval-request.rb..."
	conf = load_config("config.yml")
	req1 = Request.new("GT http://example.com HTTP/1.1123")
	req2 = Request.new("GET http://foo.bar:6969/test.png HTTP/1.1")
	r3 = Request.new("HEAD /test.txt HTTP/1.0")
	res = Response.new

	conf["allowed-methods"].each { |i| puts i }

	r3.headers["Host"] = "foo.bar"

	puts req1.print()

	puts "-----"

	puts evalReq(req1, res, conf).print
	
	puts "------"
	puts req2.print()
	puts "------"
	res = Response.new

	puts evalReq(req2, res, conf).print
	res=Response.new
	puts "====-=-=-=-=-=---=---==="
	puts r3.print
	puts "+_+_+_+_+_+_+_+_+_+_+_+_+_+_+"
	puts evalReq(r3,res,conf).print
end
