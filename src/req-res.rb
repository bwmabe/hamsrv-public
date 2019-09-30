require_relative "responses"
require_relative "time-date"

class Request
	# @param the whole request as a multi-line string
	#  or nothing at all
	def initialize(req)
		if req != nil
			unless req.respond_to? :include?
				raise ArgumentError "must be string"
			end

			@directive = ""
			@method = ""
			@uri = ""
			@version = ""
			@headers = Hash.new
			@valid = false

			# Split request message into lines
			if req.include?("\r")
				lines = req.split("\r\n")
				#puts lines
			else
				lines = req.split("\n")
			end

			if lines.length >= 1
				#main branch
				@directive = lines[0].split(' ')

				if @directive.length == 3
					@method = @directive[0]
					#puts "M" + @method
					@uri = @directive[1]
					#puts "U" + @uri
					@version = @directive[2]
					
					# inputs headers
					# headerLines = lines[1...lines.length]] 
					# @headers = headerLines.split(":")
					headerLines = lines[1...lines.length]
					headerLines.each { |i| j = i.split(": "); 
							@headers[j[0]] = j[1];}
					
					# Was going to process empty headers here, but RFC 7231 allows this
				
					# Extract host for URI validation
					#host = @headers.each { |i,j| return j if i == "Host"}

					#validate method
					#validate uri
					#validate version
				end
			end
			
			
		else
			@directive = ""
			@method = ""
			@uri = ""
			@version = ""
			@headers = Hash.new	# Empty by default
			@valid = false		# Initialzed to false
			@responseCode = 200	# Defaults to 200 OK
		end
	end

	attr_reader :valid, :uri, :headers, :method, :version
	attr_writer :headers

	def fname
		temp = @uri.split("/")
		return temp[temp.length()-1]
	end

	def path
		temp = @uri.split("/")
		path = '.'
		if temp.include?("http:")
			temp[3..(temp.length-1)].each { |i| path += "/" + i if i != ""}
		else
			temp[1..(temp.length-1)].each { |i| path += "/" + i if i != "" }
		end
		return path
	end

	def fullFname
		return path + "/" + fname
	end

	def print()
		headerstring = ''
		@headers.each{ |i,j| headerstring += i + ": " + j + "\r\n" }
		return @method + " " + @uri + " " + @version + "\r\n" +headerstring
	end

	def debugPrint
		#puts @directive + ":"
		puts @method + ":"
		puts path() +":"
		headers.each { |i| puts i[0] + "::" + i[1] }
	end
		
end


class Response
	def initialize()
		@version = 'HTTP/1.1 '
		@status = ''
		@headers = Hash.new
		@body = ''

		@headers["Server"] = "hamsrv 0.0.1"
	end

	attr_accessor :status, :body
	attr_reader :version
	attr_writer :headers

	def statusline
		@statusline = @version + @status
	end
	def headerStr
		s = ''
		@headers.each do |key, value|
			s += key + ": " + value + "\r\n"
		end
		return s
	end

	def addHeader(key, value)
		@headers[key] = value
	end

	def statusAndHeaders
		@headers["Date"] = HamDate.new.now
		@headers["Connection"] = "close"

		return  @version + @status + "\r\n" + self.headerStr + "\r\n"
	end

	def print
		return statusAndHeaders + body
	end
		
end


if __FILE__ == $0
	r = Request.new("GET /a1-test/a1-test/ HTTP/1.1\r\nHost: cs531-bmabe\r\nConnection: close")
	r2 = Request.new("GET http://test.com/a1-test/a1-test/ HTTP/1.1\r\nConnection: close")
	
	r.debugPrint
	r2.debugPrint
end
