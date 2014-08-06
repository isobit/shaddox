module Shaddox
	class RunError < StandardError ; end
	class Shadow
		def initalize(options, &block)
			@pm = options[:pm]
			@required = true
			instance_eval(&block)
		end

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def sh(command, args = nil)
			line = "#{command}"
			line += " #{args.join(" ")}" if args
			system(command, *args)
			if $? != 0 and @required
				raise RunError, "#{line} failed"
			end
		end

		def install(package)
			puts "Installing #{package} using #{@pm}"
		end
	end
end
