module Shaddox
	def warn(msg)
		puts msg.yellow
	end

	def err(msg)
		puts msg.red
	end

	def info(msg)
		puts msg
	end

	class Shadow
		def warn(msg)
			warn("	#{msg}")
		end
		def err(msg)
			err("	#{msg}")
		end
		def info(msg)
			info("	=> #{msg}")
		end
	end
	class Config
		def warn(msg)
			warn("> #{msg}")
		end
		def err(msg)
			err("> #{msg}")
		end
		def info(msg)
			info("> #{msg}")
		end
	end
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
end
