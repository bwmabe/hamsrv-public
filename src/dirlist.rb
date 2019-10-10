def genDirListing(fname, webroot)
	list = Dir.entries(fname)
	
	fname = fname.split(webroot[0])[-1]
	files = list.select{|f| !File.directory? "./" + webroot[0] + fname + f}
	dirs =  list.select{|f| File.directory? "./" + webroot[0] + fname + f}


	dirs.delete(".")
	dirs.delete("..")
	#return 501 error page

	html_start = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body>\n<h1>Index of $LOC</h1><ul>"
	html_end = "</body></html>"

	link_start = "<li><a href=\"$PATH\">$FNAME</a></li>\n"

	# line format: link_start\tsize\tmodified

	html_start.gsub!("$LOC", fname)

	body = ""
	
	dirs.each{|i| 	temp = link_start.sub("$FNAME",i + "/"); 
			temp.sub!("$PATH", fname + i);
			temp += File.open("./" + webroot[0] + fname + i).mtime.to_s
			body += temp
		 }
	files.each{|i| temp = link_start.sub("$FNAME", i);
		       body += temp.sub("$PATH",fname + i) + "\n" }
	
	return html_start + "\n" + body + html_end
end
