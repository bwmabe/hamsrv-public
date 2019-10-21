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

def connection(client, config)
	ip = client.peeraddr[-1]
	puts "connected to #{ip}:#{config["port"]}"
	
	#message = ''
	rcv = false
	timeout = true
	lastRequest = Time.now
	request = ''
	lines = [] 
	response = Response.new

	Thread.start(client) do |c|
		begin
			c.each_line do |l|
				lines.append l
				if lines.last == "\n" || lines.last() == "\r\n"
					request = lines.join
					lines = []
					rcv = true
				end
				lastRequest = Time.now
			end
		rescue IOError
		end
	end
	loop do
		# If the message is not empty; process the request form the client
		
		if rcv
			rcv = false
			unless request.empty?
				# lastRequest = Time.now
				# request, response, client ip, config file
				unless isBlank?( config["web-root"] )
					req = Request.new(request, config["web-root"])
					evalReq(req, response, ip, config)
				else
					req = Request.new(request)
					evalReq(req, response, ip, config)
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
					client.write response.print
					request = ''
				rescue IOError
					puts "Client disconnected before message could be sent"
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
