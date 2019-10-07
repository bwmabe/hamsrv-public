list = Dir.entries(loc)
files = list.select{|f| !File.directory? f}
dirs =  list.select{|f| File.directory? f}

html = "<!DOCTYPE html>\n<html><head><title>Index of $LOC</title></head>\n<body><h1></h1></body></html>"
