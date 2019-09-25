require_relative "responses"

class Request
	# @param the whole request as a multi-line string
	#  or nothing at all
	def initialize(req)
		if req != nil
			unless req.respond_to? :split?
				raise ArgumentError "must be string"
			end

			@directive = ""
			@method = ""
			@uri = ""
			@version = ""
			@headers = nil
			@valid = false
			

			# Split request message into lines
			if req.includes?("\r")
				lines = req.split("\r\n")
			else
				lines = req.split("\n")
			end

			if lines.length > 1
				#main branch
				@directive = lines[0].split(' ')
				
				if @directive.length == 3
					@method = @directive[0]
					@uri = @directive[1]
					@version = @directive[2]
					
					# inputs headers
					# headerLines = lines[1...lines.length]] 
					# @headers = headerLines.split(":")
					headerLines = lines[1...lines.length]
					headerLines.each { |i| j = i.split(":"); @headers[j[0]] = j[1] }
					
					# Was going to process empty headers here, but RFC 7231 allows this
				
					# Extract host for URI validation
					host = @headers.each { |i,j| return j if i == "Host"}

					#validate method
					#validate uri
					#validate version
				else
					@responseCode = 401 # Bad request
				end
			else
				@responseCode = 401 # Bad request
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

	def responseCode()
		return @responseCode.to_s() + " " + RESPONSES[@responseCode] + "\r\n"
	end
	
	attr_reader :valid, :uri, :headers, :method

	def parse(reqString)
		tempArr =  @directive.split(' ')
		
	end
end


class Response
	def initialize()
		@version = 'HTTP/1.1 '
		@status = ''
		@headers = Hash.new
		@body = ''
	end

	attr_accessor :status, :body
	attr_reader :version
	attr_writer :headers

	def statusline
		@statusline = @version + @status
	end
	def headers
		s = ''
		@headers.each do |key, value|
			s += key + ": " + value + "\n"
		end
		return s
	end
end
	
