require_relative "req-res"
require_relative "responses"
require_relative "config-loader"
require_relative "mime"

def evalReq(request, response, config)
	if __FILE__ == $0
		debug = true
	end

	#check method
	response.status = RESPONSES[501]; return response if !config["allowed-methods"].include?(request.method)
	#puts "method good" if debug
	
	#check uri
	# - Make sure Host is declared if uri does not begin with http://

	# Don't even attempt to make sure that the URI is usable if it contains invalid chars
	#return RESPONSES[400] if !request.uri.include?("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&()*+,;=")
	#puts "URI is all allowed chars" if debug

	if !request.uri.include?("http://")
		# If host is not in URI; bad request if host is not in headers either
		response.status = RESPONSES[400];
		 return response if !request.headers.key?("Host")
	end
	
	response.status = RESPONSES[505]; return response if request.version.split("/")[1].to_f > 1.1
	
	# Method switch goes here
	# assumes all previous checks passed
	
	# GET resource at uri to find content type
	ctype = "text/plain" #Fallback
	resource = ""

	begin
		puts request.fullFname if debug
		resource = File.new(request.fullFname, "r")
	rescue
		response.addHeader("Content-Type", ctype)
		response.status = RESPONSES[404]
		response.addHeader("DEBUG", request.fullFname)
		return response
	else
		response.addHeader("Content-Type", getMIME(request.fname))
	end

	case request.method
	when 'GET'
		# check if file exists
		# check if file readable
		response.body = resource.read
	when 'HEAD'
		# do head things
		
	when 'OPTIONS'
		# do options things
	when 'TRACE'
		# do trace things
	end
	response.status = RESPONSES[200]
	return response
end

if __FILE__ == $0
	puts "Testing eval-request.rb..."
	conf = load_config("config.yml")
	req1 = Request.new("GT http://example.com HTTP/1.1123")
	req2 = Request.new("GET http://foo.bar:6969/test.png HTTP/1.1")
	res = Response.new

	puts req1.print()

	puts "-----"

	puts evalReq(req1, res, conf).print
	
	puts "------"
	res = Response.new

	puts evalReq(req2, res, conf).print
end
