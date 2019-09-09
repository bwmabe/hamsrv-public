#!/usr/bin/env ruby

require "socket"

host = "0.0.0.0"
port = 80

port = ARGV[0] unless ARGV.empty?

socket = TCPServer.new(host,port)
puts "Listening on #{host}:#{port} ..."

loop do
	Thread.start(socket.accept) do |client|
		puts "connected to #{client}"
		#client.write("greetings #{client}!\ni'm #{host}!\n")
		
		message = client.gets
		puts "#{client} sez: " + message
		client.write message
		
		puts "disconnecting #{client}, goodbye!"

		client.close
	end
end
