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
require_relative "nonce"

LOCSTR = "\"http://.*\""

def isBlank?( *x )
	begin
		return x[0].empty?
	rescue 
		return x[0].nil?
	end
end

def genError( res, err )
res = Response.new
	res.status = RESPONSES[err]
	res.body = ERROR_PAGE(err)
	res.addHeader("Content-Type", "message/http")
	return res
end

def logAndRespond(logger, ip, req , err, fsize, res)
	res.status = RESPONSES[err]
	res.body = "" if req.directive.split[0] == "HEAD"
				if !req.fname.nil?
				res.addHeader("Content-Encoding", "gzip") if req.fname[-2..-1] == "gz"
				res.addHeader("Content-Encoding", "compress") if req.fname[-1] == "Z"
				end
	# Set transfer encoding to chunked if not overridden

	res.addHeader("Content-Language",getLang(req.fname)) if !req.fname.nil? && req.fname.include?("htm")

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

class EvalReq
	@@nonces = []
	def self.evalReq(request, response, ip, config)
	if __FILE__ == $0
		debug = true
		#config["allowed-methods"].each { |i| puts i }
	end

	#response = Response.new
	response.body = ''

	# Boolean used to differentiate between HEAD and GET
	sendBody = true

	logger = Logger.new(config)

	request.getAuthInfo()

	# Bad Request checks
	if isBlank?(request.uri)
		#response = genError(response, 400)
		response.status = RESPONSES[400]
		response.addHeader("Transfer-Encoding","chunked")
		return logAndRespond(logger,ip,request,400,0,response)
	elsif !request.headers.key?("Host")
		#response = genError(response, 400)
		#puts "a;lsdkjas;lkfj"
		response.status = RESPONSES[400]
		response.addHeader("Transfer-Encoding","chunked")
		return logAndRespond(logger,ip,request,400,0,response)
	end

	if request.raw.scan("Authorization").length > 1
		response.status = RESPONSES[400]
		response.addHeader("Transfer-Encoding","chunked")
		response.body = ERROR_PAGE(400)
		response.addHeader("Content-Length", response.body.length)
		response.addHeader("Content-Type", "text/html")
		return logAndRespond(logger,ip,request,400,response.body.length,response)
	end

	# Check for auth
	needAuth = false
	current_realm = ""
	authType = ""
	users = []
	allow = false
	methods = ""
	#nonces = []
	nc = "00000001"

	config["protected"].each{ |i|
		if request.uri.include?(i["dir"])
			needAuth = true
			current_realm = i["realm"]
			authType = i["authorization-type"]
			users = i["users"]
			if !i["methods"].empty?
				methods = ", " + i["methods"].join(", ")
			end
		end
	}

	if needAuth
		authInfo = request.getAuthInfo()
		if !authInfo.nil? && authInfo["type"] == "Basic"
			users.each{|i|
				#puts authInfo["user"]
				if authInfo["user"] == i["name"]
					allow = true if authInfo["hash"] == i["hash"]
				end
			}

			if allow
				response.addHeader("WWW-Authenticate", "Basic Realm=\"" + current_realm + "\"")
			else
				response.status = RESPONSES[401]
				response.addHeader("Transfer-Encoding", "chunked")
				@@nonces.push( genNonce(config["nonce-key"],request.debugPrint) )
				if authType == "Basic"
					response.addHeader("WWW-Authenticate", authType + " realm=\"" + current_realm + "\"")
				else
					response.addHeader("WWW-Authenticate", authType + " realm=\""+ current_realm + "\", nonce=\"" + @@nonces.last + "\"")
				end
				response.body = ERROR_PAGE(401)
				response.addHeader("Content-Type", "text/html")
				response.addHeader("Content-Length", response.body.length)
				return logAndRespond(logger,ip,request,401,response.body.length,response)
			end
		elsif !authInfo.nil? && authInfo["type"] == "Digest"
			# Check if realm correct
			allow = true
			if authInfo["realm"] != current_realm
				allow = false
			end

			# Check if nc correct
			if authInfo["nc"] != "00000001"
				allow = false
			end
			# Check if user exists/is correct
			user = nil
			users.each{|i|
				user = i if i["name"] == authInfo["username"]
			}

			if !user.nil? && allow
				a1 = user["hash"]
				a2 = Digest::MD5.hexdigest(request.method + ":" + request.uri)
				nonce = authInfo["nonce"] if @@nonces.include? authInfo["nonce"]
				if authInfo["response"] == Digest::MD5.hexdigest(a1 + ":" + nonce + ":" + authInfo["nc"] + ":" + authInfo["cnonce"] + ":" + authInfo["qop"] + ":" + a2)
					allow = true
					rspauth = Digest::MD5.hexdigest(a1 + ":" + nonce + ":" + authInfo["nc"] + ":" + authInfo["cnonce"] + ":" + authInfo["qop"] + ":" + Digest::MD5.hexdigest(":" + request.uri))
					response.addHeader("Authentication-Info","rspauth=\"" + rspauth + "\"")
				else
					allow = false
				end

			end

			# either continue or 401
		end
		if !allow
			response.status = RESPONSES[401]
			response.addHeader("Transfer-Encoding", "chunked")
			@@nonces.push(genNonce(config["nonce-key"],request.debugPrint))
				if authType == "Basic"
					response.addHeader("WWW-Authenticate", authType + " realm=\"" + current_realm + "\"")
				else
					response.addHeader("WWW-Authenticate", authType + " realm=\""+ current_realm + "\", nonce=\"" + @@nonces.last + "\"")
				end
			response.body = ERROR_PAGE(401)
			response.addHeader("Content-Type", "text/html")
			response.addHeader("Content-Length", response.body.length)
			return logAndRespond(logger,ip,request,401,response.body.length,response)
		end
	end

	# Check if method allowed
	if !config["allowed-methods"].include?(request.method)
		response.status = RESPONSES[501]
		response.addHeader("Transfer-Encoding","chunked")
		response = genError(response, 501)
		return logAndRespond(logger,ip,request,501,0,response)
	end

	# Check if client version supported
	if request.version.to_f > 1.1
		response.status = RESPONSES[505]
		response.addHeader("Transfer-Encoding","chunked")
		response = genError(response, 505)
		return logAndRespond(logger,ip,request,505,0,response)
	end

	# Do things based on method
	# GET		 - Get the file; set a bool to add in the body
	# HEAD		- get the file, clear body
	# OPTIONS - allowed methods on that file
	# TRACE	 - do trace things

	case request.method
		when 'GET'
			sendBody = true
		when 'HEAD'
			sendBody = false
		when 'OPTIONS'
			response.status = RESPONSES[200]
			response.addHeader("Allow", config["allowed-methods"].join(", ") + methods)
			return logAndRespond(logger,ip,request,200,0,response)
		when 'TRACE'
			response.addHeader("Content-Type","message/http")
			response.status = RESPONSES[200]
			response.body = request.str
			response.addHeader("Content-Length",response.body.length.to_s)
			return logAndRespond(logger,ip,request,200,response.body.length.to_s,response)
		else 
		# Repeat of Method not allowed as a failsafea
		response.status = RESPONSES[501]
		response.addHeader("Transfer-Encoding", "chunked")
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
		response.addHeader("ETag", file.gen_etag)
		response.addHeader("Last-Modified", file.mtime.hamNow)
		return logAndRespond(logger,ip, request, 200, file.size.to_i, response)
	end

	config["redirects"].each{|i|
	if !/#{i["from"]}/.match(request.uri).nil?
		temp_response = computeRedirect(request.uri, config)
		body = REDIRECT(temp_response["status"], request.host, temp_response["uri"].remEscapes)
		response.status = RESPONSES[temp_response["status"]]
		response.addHeader("Transfer-Encoding","chunked")
		response.addHeader("Location", "http://" +/#{LOCSTR}/.match(body)[0].tr("\"","").delete_suffix("/").split("http://")[-1])
		response.addHeader("Content-Type", "message/http")
		return logAndRespond(logger,ip, request, temp_response["status"], response.body.length, response)
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
				response.status = RESPONSES[200]
				
				# Handle redirect to trailing slash
				if body.include?("301 Moved Permanently")
					response.status = RESPONSES[301]
					response.addHeader("Transfer-Encoding","chunked")
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
			response.addHeader("ETag", "\""	+ file.gen_etag	+ "\"")
			response.addHeader("Last-Modified", file.mtime.hamNow)

			if request.headers.key?("If-Modified-Since")
				if newer?(file.mtime.hamNow, request.headers["If-Modified-Since"])
					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, file.size, response)
				else
					response.status = RESPONSES[304]
					response.addHeader("Transfer-Encoding","chunked")
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
					response.addHeader("Transfer-Encoding","chunked")
					response.body = ERROR_PAGE(412)
					response.headers["Content-Type"] = "text/html"
					return logAndRespond(logger, ip, request, 412, response.body.length, response)
				end
			elsif request.headers.key?("If-None-Match")
				if request.headers["If-None-Match"].is_a?(Array)
					for i in request.headers["If-None-Match"] do
						if i.lstrip.rstrip == "\"" + file.gen_etag + "\""
							response.status = RESPONSES[304]
							response.addHeader("Transfer-Encoding","chunked")
							response.body = ERROR_PAGE(304)
							return logAndRespond(logger, ip, request, 304, response.body.length, response)
						end
					end

					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, response.body.length, response)

				else
					if request.headers["If-None-Match"] == "\"" +file.gen_etag + "\""
						response.status = RESPONSES[304]
						response.addHeader("Transfer-Encoding","chunked")
						response.body = ERROR_PAGE(304)
						return logAndRespond(logger, ip, request, 304, response.body.length, response)
					else
						response.status = RESPONSES[200]
						response.body = file.read
						return logAndRespond(logger, ip, request, 200, response.body.length, response)
					end
				end
			elsif request.headers.key?("If-Match")
				if request.headers["If-Match"].strip ==	"\"" + file.gen_etag + "\""
					response.status = RESPONSES[200]
					response.body = file.read
					return logAndRespond(logger, ip, request, 200, file.size, response)
				else
					response.status = RESPONSES[412]
					response.addHeader("Transfer-Encoding","chunked")
					response.body = ERROR_PAGE(412)
					response.headers["Content-Type"] = "text/html"
					return logAndRespond(logger, ip, request, 412, response.body.length, response)
				end
			end

			# Do encodings
			#
			if request.headers.key?("Range")
				if /[(bytes=)\ \d\-\,]*/.match(request.headers["Range"])[0].nil?
					# if range doesn't match regex; bad request
					puts "BORKK"
				else
					# check that range is okay and process
					ranges = request.headers["Range"].split("=").last.split(",")
					fname = request.fullFname().remEscapes
					file = File.new(fname)
					buffer = ""
					cr = "bytes "
					ranges.each{|i|
						i.strip!
						m1 = /^(\d+)-$/.match(i)
						m2 = /^(\d+)-(\d+)/.match(i)
						m3 = /^-(\d+)/.match(i)
							
						if !/^(\d+)-$/.match(i).nil?
							puts fname
							for i in (m1[1].to_i)..(file.size)
								buffer.concat(IO.read(fname, 1, i).to_s)
							end
							#cr	= ", " if !cr.empty?
							cr.concat(m1[1].to_s + "-" + file.size.to_s)
						elsif !/^(\d+)-(\d+)/.match(i).nil?
							# do from x to y
							for i in (m2[1].to_i)..(m2[2].to_i)
								begin
									buffer.concat(IO.read(fname, 1, i))
								rescue
									response.status = RESPONSES[416]
									response.body = ERROR_PAGE(416)
									response.addHeader("Content-Length",response.body.length)
									response.addHeader("Content-Type","message/http")
									response.addHeader("Transfer-Encoding","chunked")
									return logAndRespond(logger,ip,request,416,response.body.length,response)
								end
							end
							#cr	= ", " if !cr.empty?
							cr.concat(m2[1].to_s + "-" + m2[2])
						elsif !/^-(\d+)/.match(i).nil?
							# do last x bytes
							x = file.size - m3[1].to_i
							for i in x..(file.size)
								buffer.concat(IO.read(fname, 1, i).to_s)
							end
							#cr	= ", " if !cr.empty?
							cr += x.to_s + "-" + file.size.to_s
						end
					}

					cr += "/" +file.size.to_s

					response.status = RESPONSES[206]
					response.body = buffer if !request.directive.include?("HEAD")
					response.addHeader("Content-Range", cr)
					response.addHeader("Content-Length", buffer.length.to_s)
					response.addHeader("Content-Type", getMIME(fname.split("/").last))
					return logAndRespond(logger,ip,request,206,buffer.length, response)

				end
			end

			response.status = RESPONSES[200]
			response.body = file.read
			return logAndRespond(logger, ip, request, 200, file.size, response)

		end
	rescue Errno::ENOENT
		# Check for difference Langs and extensions before 404-ing		
		path = request.fullFname().remEscapes.split("/")[0...-1].join("/")		
		if request.fullFname().remEscapes[-1] == "/"
        		response.status = RESPONSES[404]
			response.addHeader("Transfer-Encoding","chunked")
			response.addHeader("Content-Type", "text/html")
			response.body = ERROR_PAGE(404)
			return logAndRespond(logger, ip, request, 404, response.body.length, response)
		end
		begin
			File.new(path, "r").read
		rescue Errno::EISDIR 
		rescue Errno::ENOENT
			response.status = RESPONSES[404]
			response.addHeader("Transfer-Encoding","chunked")
			response.body = ERROR_PAGE(404)
			response.addHeader("Content-Type", "text/html")
	        	return logAndRespond(logger, ip, request, 404, response.body.length, response)
		end

		begin
			flist = Dir.entries(path)
	        rescue Errno::ENOENT
			response.status = RESPONSES[404]
			response.addHeader("Transfer-Encoding","chunked")
			response.body = ERROR_PAGE(404)
			response.addHeader("Content-Type", "text/html")
			return logAndRespond(logger, ip, request, 404, response.body.length, response)
		end

                fname = request.fullFname().remEscapes.split("/").last
		flist.keep_if{|i| i.include?(fname)}
					
		json = "{\"$F\" 1 {type $M} {length $L}}"
	        alternates = []				
		alts = flist.map{|i|
			f = path + "/" + i
			m = getMIME(i)
			l = File.new(f, "r").size.to_s
                        alternates.append([f, m, l])
			json.gsub("$F",i).gsub("$M",m).gsub("$L", l)
		}

                if(request.headers.key?("Accept-Encoding"))
                   encs = request.headers["Accept-Encoding"].split(",").map{|i| i.delete(' ').delete("q=").split(";")}
                  best = [[][-1]]
                  for i in encs
                    best = i if best.nil? or i[1].to_f > best[1].to_f
                  end

                  if best[0].empty?
                    response.status = RESPONSES[406]
                        response.body = ERROR_PAGE(406)
                        response.addHeader("Content-Type","text/html")
                        response.addHeader("Content-Length", response.body.length)
                        return logAndRespond(logger,ip,request,406,response.body.length,response)
                  else
                    begin
                      case best[1]
                        when "chunked"
                          response.status = RESPONSES[200]
                          response.addHeader("Content-Type",getMIME(fname))
                          response.body = File.new(request.fullFname().remEscapes, "r").read
                          return logAndRespond(logger,ip,request,200,response.body.length,response)
                        when "deflate"
                          response.status = RESPONSES[200]
                          response.addHeader("Content-Type",getMIME(fname))
                          response.body = File.new(request.fullFname().remEscapes+".zz", "r").read
                          return logAndRespond(logger,ip,request,200,response.body.length,response)
                        when "compress"
                          response.status = RESPONSES[200]
                          response.addHeader("Content-Type",getMIME(fname))
                          response.body = File.new(request.fullFname().remEscapes+".Z", "r").read
                          return logAndRespond(logger,ip,request,200,response.body.length,response)  
                        when "gzip"
                          response.status = RESPONSES[200]
                          response.addHeader("Content-Type",getMIME(fname))
                          response.body = File.new(request.fullFname().remEscapes+".gz", "r").read
                          return logAndRespond(logger,ip,request,200,response.body.length,response)
                        else
                          response.status = RESPONSES[406]
                          response.body = ERROR_PAGE(406)
                          response.addHeader("Content-Type","text/html")
                          response.addHeader("Content-Length", response.body.length)
                          response.addHeader("Transfer-Encoding","chunked")
                          return logAndRespond(logger,ip,request,406,response.body.length,response)
                      end
                    rescue
                        response.status = RESPONSES[406]
                        response.body = ERROR_PAGE(406)
                        response.addHeader("Transfer-Encoding","chunked")
                        response.addHeader("Content-Type","text/html")
                        response.addHeader("Content-Length", response.body.length)
                        return logAndRespond(logger,ip,request,406,response.body.length,response)
                    end
                  end
                end
                if (!request.headers.key?("Accept")) and !alts.empty?
			response.status = RESPONSES[300]
			response.addHeader("Transfer-Encoding","chunked")
			response.body = ERROR_PAGE(300)
			response.addHeader("Content-Type", "text/html")
			response.addHeader("Alternates", alts.join(", "))
			return logAndRespond(logger, ip, request, 300, response.body.length, response)
		end

                begin
                  accepts = request.headers["Accept"].split(",").map{|i| i.delete(' ').delete("q=").split(";")}
                rescue
                  response.status = RESPONSES[404]
		  response.addHeader("Transfer-Encoding","chunked")
		  response.body = ERROR_PAGE(404)
		  response.addHeader("Content-Type", "text/html")
		  return logAndRespond(logger, ip, request, 404, response.body.length, response)
                end

               
                payload = false
                best = nil

                for i in accepts
                  if i[0].include?("*")
                    for j in alternates
                      begin
                        best = j if j[1].include?(i[0].split("/")[0]) and best[1].to_f < i[1].to_f
                      rescue NoMethodError
                        best = j if j[1].include?(i[0].split("/")[0])
                      end
                    end
                  else
                    for j in alternates
                      
                      begin
                        best = j if j[1] == i[0] and best[1].to_f < i[1].to_f
                      rescue NoMethodError
                        best = j if j[1] == i[0]
                      end
                    end
                  end
                end
              
                if !best.nil?
                  response.status = RESPONSES[200]
                  response.body = best[0]
                  response.addHeader("Content-Type", best[1])
                  response.addHeader("Content-Length", best[2])
                  logAndRespond(logger, ip, request, 200, best[2], response)
                else
                  response.status = RESPONSES[406]
                  response.body = ERROR_PAGE(406)
                  response.addHeader("Content-Type", "text/html")
                  response.addHeader("Content-Length", response.body.length)
                  logAndRespond(logger, ip, request, 406, response.body.length, response)
                end

		# 404 stuff
		response.status = RESPONSES[404]
		response.addHeader("Transfer-Encoding","chunked")
		response.body = ERROR_PAGE(404)
		response.addHeader("Content-Type", "text/html")
		return logAndRespond(logger, ip, request, 404, response.body.length, response)
	end

	response = Response.new
        response.status = RESPONSES[400]
	response.addHeader("Transfer-Encoding","chunked")
	response.body = ERROR_PAGE(400)
	return logAndRespond(logger, ip, request, 400, response.body.length, response)
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
