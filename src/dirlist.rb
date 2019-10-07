def genDirListing(fname, webroot)
	begin
		if File.directory?(fname)
			list = Dir.entries(fname)
		else
			list = Dir.entries(fname.realdirpath.sub(fname,""))
		end
		
		list.split!(webroot)[-1]

		files = list.select{|f| !File.directory? f}
		dirs =  list.select{|f| File.directory? f}
	rescue
		#return 501 error page
	end

	html-start = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body><h1></h1>"
	html_end = "</body></html>"

	link_start = "<a href=\"$PATH\">$FNAME<a>"

	# line format: link_start\tsize\tmodified

	html_start.sub!("$LOC", list)
end
