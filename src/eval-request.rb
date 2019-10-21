require_relative "req-res"
require_relative "responses"
require_relative "config-loader"
require_relative "mime"
require_relative "escape"
require_relative "logger"
require_relative "time-date"
require_relative "etag"
require_relative "dirlist"
require_relative "redirects"

LOCSTR = "\"http://.*\""

def isBlank?( *x )
	begin
		return x[0].empty?
	rescue 
		return x[0].nil?
	end
end

def evalReq(request, response, ip, config)
	if __FILE__ == $0
		debug = true
		#config["allowed-methods"].each { |i| puts i }
	end
	
	logger = Logger.new(config)
	
	# Garbled request
	if isBlank?(request.uri)
		puts request.uri if debug
		response.status = RESPONSES[400]
		response.body = ERROR_PAGE(400)
		response.addHeader("Content-Type","message/http")
		#response.body = request.debugPrint
		logger.log(ip, request.directive, 400, 0)
		return response
	end

	if request.version > 1.1
		response.status = RESPONSES[505]
		response.body = ERROR_PAGE(505)
		response.addHeader("Content-Type","message/http")	
		logger.log(ip, request.directive, 505, 0)
		return response
	end

	if !config["allowed-methods"].include?(request.method)
		response.status = RESPONSES[501]
		response.body = ERROR_PAGE(501)
		response.addHeader("Content-Type","message/http")	
		logger.log(ip, request.directive, 501, 0)
		return response
	end

	# Check that host is defined
	if request.host.empty? and !request.headers.key?("Host")
		puts "no host" if debug
		response.status = RESPONSES[400]
		response.body = ERROR_PAGE(400)
		response.addHeader("Content-Type","message/http")	
		logger.log(ip, request.directive, 400, 0)
		return response
	end
		
	# check if file found
	config["redirects"].each{|i|
		if !/#{i["from"]}/.match(request.uri).nil?
			temp_response = computeRedirect(request.uri, config)
			body = REDIRECT(temp_response["status"],request.host,temp_response["uri"].remEscapes)
			response.status = RESPONSES[temp_response["status"]]
			response.addHeader("Location", /#{LOCSTR}/.match(body)[0].tr("\"","").delete_suffix("/"))
			response.addHeader("Content-Type","message/http")	
			return response
		end
	}
	begin
		if request.uri == "/.well-known/access.log" && request.method != "TRACE"
			file = File.new( config['log-file'], 'r')
		elsif request.method != "TRACE"
			file = File.new( request.fullFname().remEscapes,"r" )
		end
	rescue
		response.status = RESPONSES[404]
		logger.log(ip, request.directive, 404, 0)
		response.body = ERROR_PAGE(404)
		return response
	else
		if request.method != "TRACE"
			begin
				body = file.read
				clen = file.size.to_s
				ctype = getMIME(request.filename)
			rescue
				body = genDirListing(request.fullFname().remEscapes, request.root, request.host)
				clen = body.length.to_s
				ctype = "text/html"
				if body.include?("301 Moved Permanently")
					response.status = RESPONSES[301]
					response.addHeader("Location", /#{LOCSTR}/.match(body)[0].tr("\"",""))
					response.addHeader("Content-Type", ctype)
					response.addHeader("Content-Length", clen)
					response.body = body
					return response
		response.addHeader("Content-Type","message/http")	
				end
				
			end
			response.addHeader("Last-Modified", file.mtime.hamNow)
			response.addHeader("ETag", "\"" + file.gen_etag + "\"")
			response.addHeader("Content-Type", ctype)
			response.addHeader("Content-Length", clen)
			#logger.log(ip, request.directive, 200, file.size.to_s)
			# Moved to under the 'GET' branch 
		end
	end
	# add

	case request.method
	when 'GET'
		# check if file exists
		# check if file readable
		# Above are done outside of GET method branch
		if request.headers.key?("If-Modified-Since")
			# compare dates
			if newer?(file.mtime.hamNow,request.headers["If-Modified-Since"])
				response.status = RESPONSES[200]
				response.body = body
				logger.log(ip, request.directive, 200, file.size.to_s)
				return response
			else
				response.status = RESPONSES[304]
				logger.log(ip, request.directive, 304, 0)
				return response
			end
		elsif request.headers.key?("If-Unmodified-Since")
			if !newer?(file.mtime.hamNow,request.headers["If-Unmodified-Since"])
                                response.status = RESPONSES[200]
                                response.body = body
                                logger.log(ip, request.directive, 200, file.size.to_s)
                                return response
                        else
                                response.status = RESPONSES[412]
				response.body = ERROR_PAGE(412)
                                logger.log(ip, request.directive, 412, 0)
                                return response
                        end
		elsif request.headers.key?("If-Match")
			if response.headers["ETag"] == request.headers["If-Match"].lstrip.rstrip
				response.status = RESPONSES[200]
				response.body = body
				logger.log(ip, request.directive, 200, file.size.to_s)
				return response
			else
				response.status = RESPONSES[412]
				response.body = ERROR_PAGE(412)
				logger.log(ip, request.directive, 412, 0)
				return response
			end
		elsif request.headers.key?("If-None-Match")
			if request.headers["If-None-Match"].is_a?(Array)
				for i in request.headers["If-None-Match"] do
					if i.lstrip.rstrip == "\"" + file.gen_etag + "\""
						response.status = RESPONSES[304]
						response.body = ERROR_PAGE(304)
						logger.log(ip, request.directive, 304, 0)
						return response
					end
				end
			else
				if request.headers["If-None-Match"] == "\"" + file.gen_etag + "\""
					response.status = RESPONSES[304]
					logger.log(ip, request.directive, 304, 0)
					response.body = ERROR_PAGE(304)
					return response
				else
					response.status = RESPONSES[200]
					response.body = body
					logger.log(ip, request.directive, 200, file.size.to_s)
					return response
				end
			end
		end
		response.body = body
	when 'HEAD'
		# do head things
		# shouldn't have to anything since everything is done above
		#response.status = RESPONSES[200]
		#response.body = "\r\n"
		if request.headers.key?("If-Modified-Since")
			# compare dates
			if newer?(file.mtime.hamNow,request.headers["If-Modified-Since"])
				response.status = RESPONSES[200]
				#response.body = body
				logger.log(ip, request.directive, 200, file.size.to_s)
				return response
			else
				response.status = RESPONSES[304]
				logger.log(ip, request.directive, 304, 0)
				return response
			end
		elsif request.headers.key?("If-Unmodified-Since")
			if !newer?(file.mtime.hamNow,request.headers["If-Unmodified-Since"])
                                response.status = RESPONSES[200]
                                #response.body = body
                                logger.log(ip, request.directive, 200, file.size.to_s)
                                return response
                        else
                                response.status = RESPONSES[412]
                                logger.log(ip, request.directive, 412, 0)
                                return response
                        end
		elsif request.headers.key?("If-Match")
			if response.headers["ETag"] == request.headers["If-Match"].lstrip.rstrip
				response.status = RESPONSES[200]
				#response.body = body
				logger.log(ip, request.directive, 200, file.size.to_s)
				return response
			else
				response.status = RESPONSES[412]
				logger.log(ip, request.directive, 412, 0)
				return response
			end
		elsif request.headers.key?("If-None-Match")
			if request.headers["If-None-Match"].is_a?(Array)
				for i in request.headers["If-None-Match"] do
					if i.lstrip.rstrip == "\"" + file.gen_etag + "\""
						response.status = RESPONSES[304]
						logger.log(ip, request.directive, 304, 0)
						return response
					end
				end
			else
				if request.headers["If-None-Match"] == "\"" + file.gen_etag + "\""
					response.status = RESPONSES[304]
					logger.log(ip, request.directive, 304, 0)
					return response
				else
					response.status = RESPONSES[200]
					#response.body = body
					logger.log(ip, request.directive, 200, file.size.to_s)
					return response
				end
			end
		end
		logger.log(ip, request.directive, 200, file.size.to_s)
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
		response.body = request.str
		response.addHeader("Content-Length", response.body.length.to_s)
		logger.log(ip, request.directive, 200, response.body.length.to_s)
		return response
		
	end
	response.status = RESPONSES[200]
	return response
end

if __FILE__ == $0
	puts "Testing eval-request.rb..."
	conf = load_config("config.yml")
	req1 = Request.new("GT http://example.com HTTP/1.1123")
	req2 = Request.new("GET http://foo.bar/asdf/mercury/test.png HTTP/1.1")
	r3 = Request.new("HEAD /test.txt HTTP/1.0")
	r4 = Request.new("HEAD /a1-test/2/index.html HTTP/1.1\r\nHost: cs531-bmabe\r\nConnection: close")
	r5 = Request.new("GET /a2-test/ HTTP/1.1\r\nHost: cs531-bmabe", conf["web-root"])
	res = Response.new

	ip = "69.69.69.69"

	#puts evalReq(req1, res, ip, conf).print
	puts "------"
	puts req2.print()
	puts "------"
	res = Response.new
	puts evalReq(req2, res, ip, conf).print

#	res=Response.new
#	puts "====-=-=-=-=-=---=---==="
#	puts r3.print
#	puts "+_+_+_+_+_+_+_+_+_+_+_+_+_+_+"
#	puts evalReq(r3,res,ip,conf).print

#	res=Response.new
#	puts "_)(_)*)(*)(*^(*&^)*&)*(&)(*)"
#	puts r4.print 
#	puts "-------"
#	puts evalReq(r4,res,ip,conf).print

#	res=Response.new
#	puts "--------"
#	puts r5.print
#	puts "--------[][][]["
#))))	puts evalReq(r4,res,ip,conf).print
end
