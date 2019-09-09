#!/usr/bin/env ruby

require "socket"

#Reads in input from gets until 
def gets_multiline(client)
        text = ''
        line = 'a'

        while line != '' do
                line = client.gets.chomp
                text += line + "\n" unless line.empty?
        end

        return text
end

host = "0.0.0.0"  #host is hardcoded for now; will switch to arg
port = 80	  #default port of 80, overidden by 1st argument

port = ARGV[0] unless ARGV.empty?

socket = TCPServer.new(host,port)
puts "Listening on #{host}:#{port} ..."

loop do
	Thread.start(socket.accept) do |client|
		puts "connected to #{client}"
		client.write("This is an echo server!\nI repeat what you say")
		client.write("\n...until the first empty line that is...\n")
		
		message = gets_multiline(client)
		puts "#{client} sez: " + message
		client.write message
		
		puts "disconnecting #{client}, goodbye!"

		client.close
	end
end
