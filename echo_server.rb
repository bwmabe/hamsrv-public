#!/usr/bin/env ruby

require "socket"

host = "0.0.0.0"  #host is hardcoded for now; will switch to arg
port = 80	  #default port of 80, overidden by 1st argument

port = ARGV[0] unless ARGV.empty?

socket = TCPServer.new(host,port)
puts "Listening on #{host}:#{port} ..."

loop do
	Thread.start(socket.accept) do |client|
		puts "connected to #{client}"
		client.write("This is an echo server!\nI repeat each line\n")
		client.write("until you disconnect\n")
		message = 'a'

		while true do
			message = client.gets("\n")
			
			unless message.nil?
				puts "#{client} sez: " + message
				client.write "> " + message 
			end
		end

		puts "disconnected from #{client}"		
	end
end
