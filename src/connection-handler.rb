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
				evalReq(Request.new(request, config["web-root"]), response, ip, config)
			else
				evalReq(Request.new(request), response, ip, config)
			end

			# Send the response
			client.write response.print
		end
	end

	puts "disconnected from #{ip}:#{config["port"]}"
end
