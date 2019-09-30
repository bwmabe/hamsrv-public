require "date"

class HamDate
	@time = Time.now
	@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"

	def initialize()
		@time = Time.now
		@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
	end

	def logTime()
		@time = Time.now
		return @time.strftime("%d/%b/%Y:%H:%M:%S %z")
	end

	def now()
		@time = Time.now
		@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
		return @httpTime
	end
end

#time = HamDate.new

#puts time.now()


if __FILE__ == $0
	puts HamDate.new.logTime()
end
