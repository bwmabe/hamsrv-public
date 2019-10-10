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

def handleConnection(client,config)
	ip = client.peeraddr[-1]
	puts "connected to #{ip}:#{config["port"]}"
	
	#message = ''
	close = false
	timeout = false
	
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
			lastRequest = Time.now
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
				elsif req.headers["Connection"].include? "keep-alive"
					timeout = true
				end
			end
			client.write response.print
		end

		if Time.now.to_i - lastRequest.to_i >= config["timeout"].to_i && timeout
			response = Response.new
			response.status = RESPONSES[408]
			#response.body = ERROR_PAGE(408)
			client.write response.print
			close = true
			timeout = false
		end
	end
	client.close
	timeout = false
	puts "disconnected from #{ip}:#{config["port"]}"
end
