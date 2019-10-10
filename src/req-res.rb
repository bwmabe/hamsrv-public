require_relative "responses"
require_relative "time-date"

class Request
	# @param the whole request as a multi-line string
	#  or nothing at all
	def initialize(req, *webroot)
		@host = ""

		lines = req.sub("\r","").split("\n")
		if req != nil && lines[0].lstrip! == nil
			unless req.respond_to? :include?
				raise ArgumentError "must be string"
			end
			@host = ""
			@root = webroot
			
			# Split request message into lines
			# lines = req.sub("\r","").split("\n")

			if lines.length >= 1
				# muv = m'ethod, u'ri, v'ersion
				#unless lines[0].lstrip! == nil ; end
				muv = lines[0].split(' ')
				
				begin
					@method = muv[-3]
					@uri = muv[1]
					@version = muv[2].split('/')[1].to_f
				rescue
					@method = ""
					@uri = ""
					@version = ""
				end

				# h_temp temp header array
				h_temp = lines[1..lines.length-1]
				@str = req
				@directive = lines[0].to_s
				@headers = Hash[h_temp.map { |i|  i.split(":",2)}]
				@headers.each { |i,j| j = j.lstrip; j = j.rstrip }

				if @headers.key?("If-None-Match")
					#@headers["If-None-Match"].tr!("\\",'')
					@headers["If-None-Match"] = @headers["If-None-Match"].split(",")
				end
				
#				if @headers.key?("If-Match") || @headers.key?
				
				begin
					if @headers.key?("Host") && !@uri.include?("http://"+@host)
						@host = @headers["Host"]
						@file_cannonical = @uri
					else
						@host = @uri.split("http://")[-1].split("/")[0]
						@file_cannonical = @uri.split("http://"+@host)[-1]
					end

					# get path and filename
					#@file_cannonical = @uri.split("http://"+@host)[-1]
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

	attr_reader :valid, :uri, :headers, :method, :version, :filename, :file_cannonical, :host, :lines, :str, :directive, :root
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
		unless @root.empty?
			return "./" + @root[0] + @file_cannonical
		else
			return "." + @file_cannonical
		end
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
		str += "\n" + "CANNONICAL:"+self.fullFname+":"
		str += "\n" + headers.to_s
		str += "\n" + @headers["If-None-Match"][0] if @headers.key?("If-None-Match")
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

	attr_accessor :status, :body, :headers
	attr_reader :version

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
		@headers["Date"] = Time.hamNow()
		#@headers["Connection"] = "close"

		return  @version + @status + "\r\n" + self.headerStr + "\r\n"
	end

	def print
		return statusAndHeaders + body
	end
		
end


if __FILE__ == $0
	webroot = "ROOT"
	r = Request.new("GET /a1-test/a1-test/ HTTP/1.1\nHost: cs531-bmabe\nConnection: close")
	r2 = Request.new("GET http://test.com/a1-test/a1-test/ HTTP/1.1\nIf-None-Match:\"aaa\",\"bbbb\",\"cccc\"\nConnection: close", "fortnite")
	r3 = Request.new("GET http://cs531-bmabe/a1-test/1/1.2/arXiv.org.Idenitfy.repsonse.xml HTTP/1.1\nHost: cs531-bmabe\nIf-Modified-Since: Wed, 09 Sep 2009 13:37:37 GMT\nConnection: close", webroot)
	
	puts r.debugPrint
	puts r2.debugPrint
	puts r3.debugPrint
end
