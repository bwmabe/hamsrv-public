class Request
	def initialize()
		@method = ''
		@object = ''
		@headers = Hash.new	# Empty by default
		@valid = false		# Initialzed to false	 
	end
end


class Response
	def initialize()
		@version = 'HTTP/1.1 '
		@status = ''
		@headers = Hash.new
		@body = ''
	end
	def status=(s)
		@status = s
	end
	def statusline
		@statusline = @version + @status
	end
	def headers=(h)
		@headers = h
	end
	def headers
		s = ''
		@headers.each do |key, value|
			s += key + ": " + value + "\n"
		end
		return s
	end
end
	
