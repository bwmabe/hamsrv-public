require "date"

MONTHS = { "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5,
	   "Jun" => 6, "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10,
           "Nov" => 11, "Dec" => 12 }

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

	def self.now()
		@time = Time.now
		@httpTime = @time.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
		return @httpTime
	end
end

class Time
	def self.hamNow()
		return Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
	end
	
	def hamNow()
		return self.utc.strftime("%a, %d %b %Y %H:%M:%S") + " GMT"
	end
	
end

def newer?(t1,t2)
	t1regex = /(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d\d (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d\d\d\d \d\d:\d\d:\d\d GMT/.match(t1)
	t2regex =  /(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d\d (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d\d\d\d [0-2][0-9]:[0-5][0-9]:[0-5][0-9] GMT/.match(t2)
	begin
		if !t2regex.nil? || !t1regex.nil?
			
			t1d, t1month, t1y, t1time = t1regex[0].split[1..4]
			t2d, t2month, t2y, t2time = t2regex[0].split[1..4]
			t1h, t1m, t1s = t1time.split(":").map{|i| i.to_i}
			t2h, t2m, t2s = t2time.split(":").map{|i| i.to_i}

			return false if t1y == t2y && t1month == t2month && t1d == t2d && t1h == t2h && t1m == t2m && t1s == t2s

			# Compare years
			return false if t1y.to_i < t2y.to_i
			return true if t1y.to_i > t2y.to_i

			# Compare months
			return false if MONTHS[t1month] < MONTHS[t2month]
			return true if MONTHS[t1month] > MONTHS[t2month]
		
			# Compare Days
			return false if t1d.to_i < t2d.to_i
			return true if t1d.to_i > t1d.to_i
		
			# Compare time
			return false if t1h < t2h
			return true if t1h > t2h
	
			return false if t1m < t2m
			return true if t1m > t2m
		
			return false if t1s < t2s

		end
	rescue
		return true
	end

	# If the times can't be compared, just ignore and return true
	return true
	
end

#time = HamDate.new

#puts time.now()


if __FILE__ == $0
	puts HamDate.new.logTime()
	puts Time.hamNow

	t1 = Time.hamNow()
	sleep 3
	t2 = Time.hamNow()
	puts newer?(t1, t2)
	puts newer?(t1, t1)
end
