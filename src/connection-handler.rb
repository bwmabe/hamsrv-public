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
  #return false if !response.headers.key?("Transfer-Encoding")
  #return true  if response.headers["Transfer-Encoding"].include?("hunked")
  #puts "BROKEN"
  return false
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
				rescue NoMethodError
					client.write response.print
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
