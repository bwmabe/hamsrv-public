#!/usr/bin/env ruby

require "socket"
require "date"
require_relative "src/config-loader"
require_relative "src/req-res"

#Config hierarchy from last to first is
#  args > file > hardcoded
host = "0.0.0.0"  #host is hardcoded for now; will switch to arg
port = 80	  #default port of 80, overidden by 1st argument

#Config file loaded here
config = load_config("config.yml")
host = config['host']
port = config['port']

port = ARGV[0] unless ARGV.empty?

time = Time.now

response = Response.new
response.status = '200 OK' #status is hard coded to 200 for testing;

headers = {
		"Date" => "2019 06 06 13:37:08",
		"Server" => "hamsrv 0.0.1",
		"Last-Modified" => "never",
		"Content-Length" => "4",
		"Content-Type" => "text/plain",
		"Connection" => "close",
		"Allow" => "all"
	  }
response.headers = headers

socket = TCPServer.new(host,port)
puts "Listening on #{host}:#{port} ..."

loop do
	Thread.start(socket.accept) do |client|
		puts "connected to #{client}"
		message = 'a'

		while true do
			time = Time.now
			message = client.gets("\n")
			
			unless message.nil?
				puts "#{client} " + message
				headers["Date"] = time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
				headers["Content-Length"] = message.length.to_s
				response.headers = headers
				client.write response.statusline + "\n" + response.headers + "\n\n" + message 
			end
		end

		puts "disconnected from #{client}"		
	end
end
