require_relative 'time-date'
require 'digest'

def gen_etag(fname)
	File.open(fname, "r")
	return File.mtime.utc.strftime("%Y%m%d%H%M%S") + "-" + Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(fname))[0..16]
end

class File
	def gen_etag
		return self.mtime.utc.strftime("%H%M%S") + "-" + Digest::SHA256.hexdigest(self.path)[0..16]
	end
end
if __FILE__ == $0
	f = File.open("../hamsrv/test.html","r")
	puts f.gen_etag
end
