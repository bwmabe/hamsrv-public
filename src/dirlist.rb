def genDirListing(fname, webroot)
	list = Dir.entries(fname)
	
	fname = fname.split(webroot[0])[-1]
	files = list.select{|f| !File.directory? "./" + webroot[0] + fname + f}
	dirs =  list.select{|f| File.directory? "./" + webroot[0] + fname + f}


	dirs.delete(".")
	dirs.delete("..")
	#return 501 error page

	html_start = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body>\n<h1>Index of $LOC</h1><table style=\"width:50\%\"><thead><tr><th align=\"left\"><b>Filename</b></th><th align=\"right\"><b>Size</b></th><th align\"right\"><b>Last Modified</b></th></tr></thead><tbody>"
	html_end = "</tbody></table></body></html>"

	link_start = "<tr><td align=\"left\"><a href=\"$PATH\">$FNAME</a></td>"

	# line format: link_start\tsize\tmodified

	html_start.gsub!("$LOC", fname)

	body = ""
	
	dirs.each{|i| 	temp = link_start.sub("$FNAME",i + "/"); 
			temp.sub!("$PATH", fname + i);
			f = File.open("./" + webroot[0] + fname + i)
			temp += "<td align = \"right\">" + f.size.to_s+ "<td align=\"right\">" + f.mtime.strftime("%I:%M:%S - %B %d %Y") + "</td></tr>"
			body += temp
		 }
	files.each{|i| temp = link_start.sub("$FNAME",i + "/"); 
			temp.sub!("$PATH", fname + i);
			f = File.open("./" + webroot[0] + fname + i)
			temp += "<td align=\"right\">" + f.size.to_s + "<td align=\"right\">" + f.mtime.strftime("%I:%M:%S - %B %d %Y") + "</td></tr>"
			body += temp }
	
	return html_start + "\n" + body + html_end
end
