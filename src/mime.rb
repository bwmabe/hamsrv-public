#MIME_TYPES = ["text/plain", "text/html", "text/xml", "image/png", "image/jpeg", "image/gif", "application/pdf", "application/vnd.ms-powerpoint", "application/vnd.ms-word", "message/http", "application/octet-stream"]

def getMIME(fname)
	unless fname.respond_to? :include?
		raise ArgumentError
			"arg must be string to determine MIME (was { #fname.class })"
	end

	fname = fname.dup
	fname.downcase!
	
	ext = nil
	ext = fname.split('.')
	ext = ext[ext.length - 1]
	
	case ext
	when "txt", "log"
		return "text/plain"
	when "html", "htm", "en", "es", "de"
		return "text/html"
	when "xml"
		return "text/xml"
	when "png"
		return "image/png"
	when "jpeg", "jpg"
		return "image/jpeg"
	when "gif"
		return "image/gif"
	when "pdf"
		return "application/pdf"
	when "doc", "docx"
		return "application/vnd.ms-word"
	when "ppt", "pptx", "ppts"
		return "application/vnd.ms-powerpoint"
	when "jis"
		return "text/html; charset=iso-2022-jp"
	when "koi8-r"
		return "text/html; charset=koi8-r"
	when "euc-kr"
		return "text/html; charset=euc-kr"
	when "Z","gz","z"
		return "text/html"
	else
		return "application/octet-stream"
	end	
end

def getLang(fname)
	e1 = fname.split('.').last
	e2 = fname.split('.')[-2]

	case e1
	when "de"
		return "de"
	when "en"
		return "en"
	when "es"
		return "es"
	when "ja"
		return "ja"
	when "ko"
		return "ko"
	when "ru"
		return "ru"
	else
		case e2
		when "ko"
			return "ko"
		when "ru"
			return "ru"
		when "ja"
			return "ja"
		else
			return "en"
		end
	end
end


if __FILE__ == $0
	puts getMIME("owo.pdf")
	puts getMIME("d.o.t.t.y.b.o.y.e.png.gif.pptx")
	
	begin
		puts getMIME(4)
	rescue
		puts "wrong arg okay!"
	else
		puts "wrong arg broken"
	end
end
