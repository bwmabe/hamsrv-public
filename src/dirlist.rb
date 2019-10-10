def genDirListing(fname, webroot)
	list = Dir.entries(fname)
	
	fname = fname.split(webroot[0])[-1]
	files = list.select{|f| !File.directory? "./" + webroot[0] + fname + f}
	dirs =  list.select{|f| File.directory? "./" + webroot[0] + fname + f}


	dirs.delete(".")
	dirs.delete("..")
	#return 501 error page

	html_start = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body><h1></h1>"
	html_end = "</body></html>"

	link_start = "<a href=\"$PATH\">$FNAME<a>"

	# line format: link_start\tsize\tmodified

	html_start.sub!("$LOC", fname)

	body = ""
	
	dirs.each{|i| temp = link_start.sub("$FNAME",i + "/"); 
		      body += temp.sub("$PATH", fname + i) + "\n" 
		 }
	files.each{|i| temp = link_start.sub("$FNAME", i);
		       body += temp.sub("$PATH",fname + i) + "\n" }
	
	return html_start + "\n" + body + html_end
end
