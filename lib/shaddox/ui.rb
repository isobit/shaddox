def prefix(level)
	"=" * level + "> "
end
def warn(msg, level = 0)
	puts prefix(level) + msg.yellow
end

def err(msg, level = 0)
	puts prefix(level) + msg.red
end

def info(msg, level = 0)
	out =  prefix(level)
	if level == 0
		out += msg.blue
	else
		out += msg
	end
	puts out
end

class String
	# colorization
	def colorize(color_code)
		"\e[#{color_code}m#{self}\e[0m"
	end

	def red
		colorize(31)
	end

	def green
		colorize(32)
	end

	def yellow
		colorize(33)
	end

	def blue
		colorize(34)
	end

	def pink
		colorize(35)
	end

	def cyan
		colorize(36)
	end

	def gray
		colorize(90)
	end
end
