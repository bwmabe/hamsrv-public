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
	timeout = true
	lastRequest = Time.now
	
	while !close
		message = []
		#Thread.new {while true; puts Time.now}
		response = Response.new
		rcv = 'a'
		request = ''

		# recieve the message from the client; wait until newline or blank
		Thread.start(client) do |c|
			begin
				c.each_line do |l|
					message.append l
					lastRequest = Time.now
				end
			rescue
				#supress error on disconnected
			end
		end

		# Concatenate the message
		# message.each{|i| request += i}
		# message.join
		# If the message is not empty; process the request form the client
		if message.last == "\n" || message.last == "\r\n" || message.last == ""
			request = message.join
			message = []
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
				
				timeout = true
				# Send the response
				begin
					if req.headers.key?("Connection")
						if req.headers["Connection"].include? "close"
							response.addHeader("Connection", "close")
							client.write response.print
							client.close
							close = true
							timeout = false
						elsif req.headers["Connection"].include? "keep-alive"
							timeout = true
						end
					end
				rescue
					timeout = true
				end
				client.write response.print
				request = ''
			end
			
			if ((Time.now.to_i - lastRequest.to_i) >= config["timeout"].to_i) && timeout
				response = Response.new
				response.status = RESPONSES[408]
				response.addHeader("Connection", "close")
				client.write response.print
				close = true
			end
		end
	end
	client.close
	puts "disconnected from #{ip}:#{config["port"]}"
end
