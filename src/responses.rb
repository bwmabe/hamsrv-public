RESPONSES = 
	{
		
		200 => "200 OK",
		206 => "206 Partial Content",
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

DESCRIPTIONS =
	{
		400 => "The client has sent a request that wasn't understood",
		403 => "You are forbidden from accessing this file",
		404 => "The file you have requested has not been found",
		500 => "The server is broken!",
		501 => "The requested method has not be implemented",
		505 => "That version of HTTP is not supported"
	}

PAGE_TEMPLATE = "<!DOCTYPE html>\n<html>\n<head><title>$ERR_MESSAGE</title></head>\n<body><h1>$ERR_MESSAGE</h1>$DESCRIPTION</body>\n</html>\n"

def ERROR_PAGE(err)
	page = ""
	page.replace(PAGE_TEMPLATE)
	#page.gsub!("XXX", err.to_s)
	if RESPONSES[err].nil?
		page.gsub!("$ERR_MESSAGE", RESPONSES[500])
		page.gsub!("$DESCRIPTION", DESCRIPTIONS[500])
	else
		page.gsub!("$ERR_MESSAGE",RESPONSES[err])
	
		if DESCRIPTIONS[err].nil?
			page.gsub!("$DESCRIPTION",RESPONSES[err])
		else
			page.gsub!("$DESCRIPTION",DESCRIPTIONS[err])
		end
	end

	return page
end

def REDIRECT(err, host, fname)
	page = "<!DOCTYPE HTML>\n<html><head>\n<title>$STATUS</title>\n</head><body>\n<h1>Moved Permanently</h1>\n<p>The document has moved <a href=\"http://$HOST$FULLFNAME/\">here</a>.</p>\n</body></html>\n"
	page.sub!("$STATUS",RESPONSES[err])
	page.sub!("$HOST",host.lstrip.rstrip)
	page.sub!("$FULLFNAME",fname.lstrip.rstrip)
	return page
end

if __FILE__ == $0
	File.open("test.html", "w").write(ERROR_PAGE(76897667))
	puts REDIRECT(302, "myneck", "main.rb")
end
