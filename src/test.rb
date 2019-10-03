require_relative "req-res"
require_relative "mime"

str = "GET /foo/bar/baz.jpg HTTP/1.1\nHost:Example.com\n"

req = Request.new(str)

puts req.valid 
puts req.uri
puts req.headers
puts req.method

puts getMIME(req.fname)

hsh = Hash.new

hsh[:owo] = "uwu"

puts hsh["owo"]
