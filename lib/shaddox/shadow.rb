module Shaddox
	class RunError < StandardError ; end
	class Shadow
		require 'fileutils'
		include FileUtils

		def initialize(options, &block)
			@installer = options[:installer]
			@tmppath = options[:tmppath] || '/tmp/shaddox/'
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
			raise RunError, "#{line} failed".red unless $? == 0 or !@required
		end

		def install(package)
			raise "No installer specified for this target!".red unless @installer
			puts "Installing #{package} using #{@installer}"
			unless system("type #{package} >/dev/null 2>&1")
				case @installer
				when :apt
					sh "sudo apt-get install -y #{package}"
				when :brew
					sh "brew install #{package}"
				end
			end
		end
	end
end
