RESPONSES = 
	{
		
		200 => "200 OK",
		301 => "301 Moved Permanently",
		302 => "302 Found",
		304 => "304 Not Modified",
		400 => "400 Bad Request",
		403 => "403 Forbidden",
		404 => "404 Not Found",
		408 => "408 Request Timeout",
		412 => "412 Precondition Failed",
		500 => "500 Internal Server Error",
		501 => "501 Not Implemented",
		505 => "505 HTTP Version Not Supported"
	}

PAGE_TEMPLATE = "<!DOCTYPE html>\n<html>\n<head><title>$ERR_MESSAGE</title></head>\n<body><h1>$ERR_MESSAGE</h1>$DESCRIPTION</body>\n</html>"

def ERROR_PAGE(err)
	page = ""
	page.replace(PAGE_TEMPLATE)
	#page.gsub!("XXX", err.to_s)
	page.gsub!("$ERR_MESSAGE",RESPONSES[err])

	return page
end

if __FILE__ == $0
	File.open("test.html", "w").write(ERROR_PAGE(400))
end
