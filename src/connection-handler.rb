require 'socket'

require_relative "time-date"
require_relative "config-loader"
require_relative "req-res"
require_relative "eval-request"
require_relative "responses"

def isBlank?( *x )
	begin
		return x[0].empty?
	rescue 
		return x[0].nil?
	end
end

def handleConnection(socket,config)
	Thread.start(socket.accept) do |client|
		connection(client,config)
	end
end

def chunked?(response)
  return false if !response.headers.key?("Transfer-Encoding")
  return true  if response.headers["Transfer-Encoding"].include?("hunked")
  #puts "BROKEN"
  return false
end

def sendChunked(response, client)
	sent = false
	msg = []
	#client.write response.statusAndHeaders
	clen = response.headers["Content-Length"].to_i
	begin 
		response.body.split("\n").each{|i|
			if i.length > 0
				msg.append( (i.length.to_s(16) + "\r\n" + i + "\r\n") )
				clen += i.length.to_s(16).length + 4 if !msg.last.nil?
				sent = true
			end
		}
	rescue NoMethodError
		if response.body.length > 0
			msg.append( response.body.length.to_s(16) + "\r\n" + response.body + "\r\n" )
			clen += response.body.length.to_s(16).length + 4 if !msg.last.nil?
			sent = true
		end
	end
	begin
		response.headers["Content-Length"] = (clen + 5).to_s
	rescue
		response.addHeader("Content-Length",5.to_s)
	end
	client.write response.statusAndHeaders
	msg.each{|i| client.write i} if !msg.empty?
	client.write "0\r\n\r\n" if sent
end

def connection(client, config)
	ip = client.peeraddr[-1]
	puts "connected to #{ip}:#{config["port"]}"
	
	#message = ''
	rcv = false
	timeout = true
	lastRequest = Time.now
	request = ''
	requests = Queue.new
	msg = []
	c = nil
	line = ''
	response = Response.new

	loop do
		# If the message is not empty; process the request form the client
		begin
			c = client.read_nonblock(1)
		rescue IO::EAGAINWaitReadable
			# This type of error should be ignored
		rescue IOError
			break
		end
		
		if !c.nil?
			line +=  c
			c = nil
		end

		if line[-1] == "\n"
			msg.append(line)
			if line == "\r\n" or line == "\n"
				requests << msg.join
				msg = []
			end
			line = ''
			lastRequest = Time.now
		end

		if !requests.empty?
			request = requests.pop
			rcv = false
			unless request.empty?
				# lastRequest = Time.now
				# request, response, client ip, config file
				unless isBlank?( config["web-root"] )
					req = Request.new(request, config["web-root"])
					EvalReq::evalReq(req, response, ip, config)
				else
					req = Request.new(request)
					EvalReq::evalReq(req, response, ip, config)
				end
				

				begin
					# Send the response
					if req.headers.key?("Connection")
						if req.headers["Connection"].include? "close"
							response.addHeader("Connection", "close")
							request = ''
							client.write response.print
							client.close
						end
					else
						response.addHeader("Connection", "keep-alive")
					end
					
					if chunked?(response)
						sendChunked(response, client)
					else
						client.write response.print
					end
					request = ''
				rescue NoMethodError
					if chunked?(response)
						sendChunked(response, client)
					else
						client.write response.print
					end
					request = ''
				rescue IOError
					#puts "Client disconnected before message could be sent"
					break
				end
			end
		end


		if ((Time.now.to_i - lastRequest.to_i) >= config["timeout"].to_i)
			response = Response.new
			response.status = RESPONSES[408]
			response.addHeader("Connection", "close")
			begin
				client.write response.print
				client.close
			rescue IOError
				puts "Client disconnect before timeout"
				break
			end
		end
	end
end
