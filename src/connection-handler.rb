require 'socket'

require_relative "time-date"
require_relative "config-loader"
require_relative "req-res"
require_relative "eval-request"

def isBlank?( *x )
	begin
		return x[0].empty?
	rescue 
		return x[0].nil?
	end
end

def handleConnection(client,config)
	ip = client.peeraddr[-1]
	puts "connected to #{ip}:#{config["port"]}"
	
	#message = ''
	close = false
	
	while !close
		message = []
		response = Response.new
		rcv = 'a'
		request = ''

		# recieve the message from the client; wait until newline or blank
		while ( (rcv = client.gets()) && rcv != "\n" && rcv != "\r\n" && rcv != '' )
			message << rcv
		end

		# Concatenate the message
		message.each{|i| request += i}

		# If the message is not empty; process the request form the client
		unless request.empty?
			# request, response, client ip, config file
			unless isBlank?( config["web-root"] )
				req = Request.new(request, config["web-root"])
				evalReq(req, response, ip, config)
			else
				req = Request.new(request)
				evalReq(req, response, ip, config)
			end

			# Send the response
			if req.headers.key?("Connection")
				if req.headers["Connection"].include? "close"
					response.addHeader("Connection", "close")
					close = true
				end
			end
			client.write response.print
		end
	end
	client.close
	puts "disconnected from #{ip}:#{config["port"]}"
end
