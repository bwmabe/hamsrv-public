require "digest"
require_relative 'time-date'

def genNonce(key, str)
	return Digest::MD5.hexdigest(key + str + Time.hamNow())
end

if __FILE__ == $0
	puts genNonce("a", "b")
end
