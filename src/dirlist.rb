require_relative 'responses'

def genDirListing(fname, webroot, host)
	list = Dir.entries(fname)
	
	fname = fname.split(webroot[0])[-1]
	
	# Handle 301 REDIRECTS here
	if fname[-1] != ("/")
		return REDIRECT(301, host, fname)
	end
	
	begin
		indexhtml = File.open("./" + webroot[0] + fname + "index.html","r").read
		return indexhtml
	rescue
		# Fall through to the rest of the function
	end
	
	files = list.select{|f| !File.directory? "./" + webroot[0] + fname + f}
	dirs =  list.select{|f| File.directory? "./" + webroot[0] + fname + f}

	# Doesn't actually delete the dirs from the filesystem, just this list
	dirs.delete(".")
	dirs.delete("..")
	#return 501 error page

	html_start = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body>\n<h1>Index of $LOC</h1>\n<b><a href=\"$LOC..\">Parent</a></b>\n<table style=\"width:50\%\">\n<thead>\n<tr><th align=\"left\"><b>Filename</b></th><th align=\"right\"><b>Size</b></th><th align=\"right\"><b>Last Modified</b></th>\n</tr>\n</thead>\n<tbody>"
	html_end = "</tbody></table></body></html>"

	link_start = "<tr><td align=\"left\"><a href=\"$PATH\">$FNAME</a></td>"

	# line format: link_start\tsize\tmodified

	html_start.gsub!("$LOC", fname)
  

	body = ""
	
	dirs.each{|i| 	temp = link_start.sub("$FNAME",i + "/"); 
			temp.sub!("$PATH", fname + i);
			f = File.open("./" + webroot[0] + fname + i + "/")
			temp += "<td align = \"right\"> - </td><td align=\"right\">" + f.mtime.strftime("%I:%M:%S - %B %d %Y") + "</td></tr>\n"
			body += temp
		 }
	files.each{|i| temp = link_start.sub("$FNAME",i); 
			temp.sub!("$PATH", fname + i);
			f = File.open("./" + webroot[0] + fname + i)
			temp += "<td align=\"right\">" + f.size.to_s + " bytes</td><td align=\"right\">" + f.mtime.strftime("%I:%M:%S - %B %d %Y") + "</td></tr>\n"
			body += temp }
	
	return html_start + "\n" + body + html_end
end
