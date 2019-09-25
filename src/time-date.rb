require "date"

class HamDate
	@time = Time.now
	@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"

	def initialize()
		@time = Time.now
		@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
	end

	def now()
		@time = Time.now
		@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
		return @httpTime
	end
end

#time = HamDate.new

#puts time.now()
