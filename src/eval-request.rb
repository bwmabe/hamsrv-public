require_relative "req-res"
require_relative "responses"
require_relative "config-loader"
require_relative "mime"
require_relative "escape"

def evalReq(request, response, config)
	if __FILE__ == $0
		debug = true
		#config["allowed-methods"].each { |i| puts i }
	end
	
	# Garbled request
	if request.uri.empty?
		puts request.uri if debug
		response.status = RESPONSES[400]
		#response.body = request.debugPrint
		return response
	end

	if request.version > 1.1
		response.status = RESPONSES[505]
	end

	if !config["allowed-methods"].include?(request.method)
		response.status = RESPONSES[501]
		return response
	end

	# Check that host is defined
	if request.host.empty? and !request.headers.key?("Host")
		puts "no host" if debug
		response.status = RESPONSES[400]
		response.body = request.lines.to_s
		return response
	end

	if request.uri == "/.well-known/access.log" && request.method == "GET"
		#Open the file for the access log and serve it
	end

	# check if file found
	begin
		file = File.new( request.fullFname().remEscapes,"r" )
	rescue
		response.status = RESPONSES[404]
		return response
	else
		body = file.read
		response.addHeader("Content-Type", getMIME(request.filename))
		response.addHeader("Content-Length", file.size.to_s)
	end
	# add

	case request.method
	when 'GET'
		# check if file exists
		# check if file readable
		response.body = body
	when 'HEAD'
		# do head things
		# shouldn't have to anything since everything is done above
		#response.status = RESPONSES[200]
	when 'OPTIONS'
		# do options things
		allow = ""
		config["allowed-methods"].each{ |i| allow += i + ", " }
		allow.delete_suffix!(", ")
		response.addHeader("Allow",allow)
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
	r4 = Request.new("HEAD /a1-test/2/index.html HTTP/1.1\r\nHost: cs531-bmabe\r\nConnection: close")
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
