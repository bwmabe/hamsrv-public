#!/usr/bin/env ruby

require "socket"

#Relative libraries
require_relative "src/time-date"
require_relative "src/config-loader"
require_relative "src/req-res"
require_relative "src/eval-request"

#Config hierarchy from last to first is
#  args > file > hardcoded
host = "0.0.0.0"  #host is hardcoded for now; will switch to arg
port = 80	  #default port of 80, overidden by 1st argument

#Config file loaded here
config = load_config("config.yml")
host = config['host']
port = config['port']
#puts port
allowed_methods = config["allowed-methods"]

port = ARGV[0] unless ARGV.empty?

time = HamDate.new

response = Response.new
response.status = '200 OK' #status is hard coded to 200 for testing;

socket = TCPServer.new(host,port)
puts "Listening on #{host}:#{port} ..."

loop do
	Thread.start(socket.accept) do |client|
		puts "connected to #{client}"
		message = ''

		while true do
			message = ''
			message += client.gets("\n")

			unless message.nil?
				evalReq(Request.new(message),response,config)
				client.write response.print
				client.close
			end
		end

		puts "disconnected from #{client}"		
	end
end
