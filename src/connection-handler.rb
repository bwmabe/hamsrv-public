require 'socket'

require_relative "time-date"
require_relative "config-loader"
require_relative "req-res"
require_relative "eval-request"

def handleConnection(client,config)
	puts "connected to #{client.peeraddr[-1]}:#{config["port"]}"
	
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
			evalReq(Request.new(request), response, client.peeraddr[-1],config)
			
			# Send the response
			client.write response.print
		end
	end

	puts "disconnected from #{client.peeraddr[-1]}:#{config["port"]}"
end
