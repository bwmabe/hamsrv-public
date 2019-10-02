require_relative "responses"
require_relative "time-date"

class Request
	# @param the whole request as a multi-line string
	#  or nothing at all
	def initialize(req)
		@host = ""
		if req != nil
			unless req.respond_to? :include?
				raise ArgumentError "must be string"
			end
			@host = ""
			
			# Split request message into lines
			if req.include?("\r")
				lines = req.split("\r\n")
				#puts lines
			else
				lines = req.split("\n")
			end

			if lines.length >= 1
				# muv = m'ethod, u'ri, v'ersion
				muv = lines[0].split(' ')
				
				begin
					@method = muv[0]
					@uri = muv[1]
					@version = muv[2].split('/')[1].to_f
				rescue
					@method = ""
					@uri = ""
					@version = ""
				end

				# h_temp temp header array
				h_temp = lines[1..lines.length-1]
				@str = h_temp[0]
				@headers = Hash[h_temp.map { |i|  i.split(":")}]
				puts @headers
				@headers.each { |i,j| j.lstrip!; j.rstrip! }
				
				begin
					if @headers.key?("Host")
						@host = @headers["Host"]
					else
						@host = @uri.split("http://")[-1].split("/")[0]
					end

					# get path and filename
					@file_cannonical = @uri.split("http://"+@host)[-1]
					@filename = @file_cannonical.split('/').reject { |i| i.empty? }[-1]
				rescue
					@host = ""
					@filename = ""
					@file_cannonical = ""
				end
			end
			
			
		else
			@directive = ""
			@method = ""
			@uri = ""
			@version = 1.1
			@host =  ""
			@headers = Hash.new
		end
	end

	attr_reader :valid, :uri, :headers, :method, :version, :filename, :file_cannonical, :host, :lines, :str
	attr_writer :headers, :host

	def fname
		temp = @uri.split("/")
		return temp[temp.length()-1]
	end

	def path
		temp = @uri.split("/")
		path = '.'
		if temp.include?("http:")
			temp[3..(temp.length-2)].each { |i| path += "/" + i if i != ""}
		else
			temp[1..(temp.length-2)].each { |i| path += "/" + i if i != "" }
		end
		return path
	end

	def fullFname()
		return "." + @file_cannonical
	end

	def print()
		headerstring = ''
		@headers.each{ |i,j| headerstring += i + ": " + j + "\r\n" }
		return @method + " " + @uri + " " + @version.to_s + "\r\n" +headerstring
	end

	def debugPrint
		#puts @directive + ":"
		str = ""
		str += "Method:" + @method + ":"
		str += "\n" + "URI:"+@uri+":"
		str += "\n" + "HOST:"+@host+":"
		str += "\n" + "FILE:" + @filename.to_s + ":"
		str += "\n" + "CANNONICAL:"+@file_cannonical.to_s+":"
		str += "\n" + headers.to_s
		return str
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
	r = Request.new("GET /a1-test/a1-test/ HTTP/1.1\nHost: cs531-bmabe\nConnection: close")
	r2 = Request.new("GET http://test.com/a1-test/a1-test/ HTTP/1.1\nConnection: close")
	r3 = Request.new("HEAD /a1-test/2/index.html HTTP/1.1\nHost: cs531-bmabe\nConnection: close")
	
	puts r.debugPrint
	puts r2.debugPrint
	puts r3.debugPrint
end
