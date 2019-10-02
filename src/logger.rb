# log format
# host - - [dd/Mmm/yyyy:%d/%b/%Y:%H:%M:%S %z] "method uri version" status file.size

require_relative "req-res"
require_relative "config-loader"

class Logger
	def initialize(conf)
		@cfg = conf
		@time = HamDate.new
		@host = conf['host']
		@file = conf['log-file']
	end
		 
	def log(directive, status, fsize)
		File.write(@file, @host + " - - [" + @time.logTime + "] \"" + directive + "\" " + status.to_s + " " + fsize.to_s + "\r\n", mode: "a")
	end
end
if __FILE__ == $0
	cfg = load_config("config.yml")
	lgr = Logger.new(cfg)	
	lgr.log("GET /thing/.file", 200, 128)
end
