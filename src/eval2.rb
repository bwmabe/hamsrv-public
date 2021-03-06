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

def genError( res, err )
  res = Repsonse.new
  res.stats = RESPONES[err]
  res.body = ERROR_PAGE(err)
  res.addHeader("Content-Type", "message/http")
  return res
end

def logAndRespond(logger, ip, req , err, fsize, res)
  logger.log(ip, req.directive, err, fsize)
  return res
end

def respondWithFile(logger, ip, file, req , res)
  
  # Assumes file found and successful negotiation

  res.addHeader("Last-Modified",file.mtime.hamNow)
  res.addHeader("ETag","\"" + file.gen_etag + "\"")
  res.addHeader("Content-Type", getMIME(request.filename))
  res.addHeader("Content-Length",file.size.to_s)
  
  logger.log(ip, req.directive, 200, file.size)

  return res
end

def evalReq(request, response, ip, config)
  if __FILE__ == $0
    debug = true
    #config["allowed-methods"].each { |i| puts i }
  end

  # Boolean used to differentiate between HEAD and GET
  sendBody = true

  logger = Logger.new(config)

  # Bad Request checks
  if isBlank?(request.uri)
    response = genError(response, 400)
    return logAndRespond(logger,ip,request,400,0,response)
  elsif !request.headers.key?("Host") and request.host.empty?
    response = genError(response, 400)
    return logAndRespond(logger,ip,request,400,0,response)
  end

  # Check if method allowed
  if !config["allowed-methods"].include?(request.method)
    response = genError(response, 501)
    return logAndRespond(logger,ip,request,501,0,response)
  end

  # Check if client version supported
  if request.version.to_f > 1.1
    response = genError(response, 505)
    return logAndRespond(logger,ip,request,505,0,response)
  end

  # Do things based on method
  # GET     - Get the file; set a bool to add in the body
  # HEAD    - get the file, clear body
  # OPTIONS - allowed methods on that file
  # TRACE   - do trace things

  case request.method
    when 'GET'
      sendBody = true
    when 'HEAD'
      sendBody = false
    when 'OPTIONS'
      reponse.addHeader("Allow", config["allowed-methods"].join(", ") )
      return logAndRespond(logger,ip,request,200,0,response)
    when 'TRACE'
      response.addHeader("Content-Type","message/http")
      response.status = RESPONSES[200]
      response.body = request.str
      response.addHeader("Content-Length",response.body.length.to_s)
      return logAndRespond(logger,ip,request,200,response.body.length.to_s,response)
    else 
    # Repeat of Method not allowed as a failsafe
    return logAndRespond(logger, ip, request, 501, 0, genError(response, 501))
  end


  # File Checks
  # - virtual URIs and redirecs
  # - Exists
  # - - content negotiation stuff
  # - modified/etag/accept

  # Handle the only virtual URI
  if request.uri == "/.well-known/access.log"
    file = File.new(config["log-file"],"r")
    log = file.read
    response.body = log if sendBody
    response.status = RESPONSES[200]
    response.addHeader("Content-Type", "text/plain")
    response.addHeader("Content-Length", log.length)
    repsonse.addHeader("ETag", file.gen_etag)
    response.addHeader("Last-Modified", file.mtime.hamNow)
    return logAndRespond(logger,ip, request, 200, file.size.to_i, response)
  end

  config["redirects"].each{|i|
	if !/#{i["from"]}/.match(request.uri).nil?
		  temp_response = computeRedirect(request.uri, config)
		  body = REDIRECT(temp_response["status"], request.host, temp_response["uri"].remEscapes)
		  response.status = RESPONSES[temp_response["status"]]
		  response.addHeader("Location", "http://" + /#{LOCSTR}/.match(body)[0].tr("\"","").delete_suffix("/").split("http://")[-1])
		  response.addHeader("Content-Type", "message/http")
		  return logAndRespond(logger,ip, request, 301, response.body.length, response)
	end
  }

	begin
		# Read in file here
		begin
			# Attempt to read the file
			
			# If directory...
			if File.directory?(request.fullFname().remEscapes)
				dir = request.fullFname().remEscapes

				# Check for index.html
				if File.file?(dir + "/index.html") 

				elsif File.file?(dir + "index.html")
					# Copypaste normal file reading code here
				end

				body = genDirListing(request.fullFname().remEscapes,request.root,request.host)
				clen = body.length.to_s
				ctype = "text/html"
				stat = 200
				repsonse.status = RESPONSES[200]
				
				# Handle redirect to trailing slash
				if body.include?("301 Moved Permanently")
					response.status = RESPONSES[301]
					response.addHeader("Location", /#{LOCSTR}/.match(body)[0].tr("\"",""))
					ctype = "message/http"
					stat = 301
				end

				# Returns 
				response.addHeader("Content-Type", ctype)
				response.addHeader("Content-Length", clen)
				response.body = body
				return logAndRespond(logger, ip, request, stat, clen, response)

			end

			# Content Negotiation
			# Check ETAG, Last Modified
			# Check encodings, filetype
			file = File.new(request.fullFname().remEscapes)
			response.addHeader("Content-Type", getMIME(request.fname))
			response.addHeader("Content-Length", file.size.to_s)
			response.addHeader("ETag", "\"" + file.gen_etag + "\"")
			response.addHeader("Last-Modified", file.mtime.hamNow)

			if request.headers.key?("If-Modified-Since")
				if newer?(file.mtime.hamNow, request.headers["If-Modified-Since"])
					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, file.size, response)
				else
					response.status = RESPONSES[304]
					response.body = ERROR_PAGE(304)
					return logAndRespond(logger, ip, request, 304, response.body.length, response)
				end
			elsif request.headers.key?("If-Unmodified-Since")
				if !newer?(file.mtime.hamNow, request.headers["If-Modified-Since"])
					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, file.size, response)
				else
					response.status = RESPONSES[412]
					response.body = ERROR_PAGE(412)
					return logAndRespond(logger, ip, request, 412, response.body.length, response)
				end
			elsif request.headers.key?("If-None-Match")
				if request.headers["If-None-Match"].is_a?(Array)
					for i in request.headers["If-None-Match"] do
						if i.lstrip.rstrip == "\"" + file.gen_etag + "\""
							response.status = RESPONSES[304]
							response.body = ERROR_PAGE(304)
							return logAndRespond(logger, ip, request, 304, response.body.length, response)
						end
					end

					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, response.body.length, response)

				else
					if request.headers["If-None-Match"] == "\"" + file.gen_etag + "\""
						response.status = RESPONSES[304]
						response.body = ERROR_PAGE(304)
						return logAndRespond(logger, ip, request, 304, response.body.length, response)
					else
						response.status = RESPONSES[200]
						response.body = file.read
						return logAndRespond(logger, ip, request, 200, response.body.length, response)
					end
				end
			end

			# Do encodings 
			response.status = RESPONSES[200]
			response.body = file.read
			return logAndRespond(logger, ip, request, 200, file.size, response)

		end
	rescue Errno::ENOENT
		# 404 stuff
		response.status = RESPONSES[404]
		response.body = ERROR_PAGE(404)
		return logAndRespond(logger, ip, request, 404, response.body.length, response)
	end
	
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

end
