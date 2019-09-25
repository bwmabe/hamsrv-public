class Request
	def initialize()
		@method = ""
		@uri = ""
		@version = ""
		@headers = Hash.new	# Empty by default
		@valid = false		# Initialzed to false	 
	end
	def parse(reqString)
		
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
	
