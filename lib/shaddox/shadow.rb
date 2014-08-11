class String
	def exp_path
		File.expand_path(self)
	end
end

module Shaddox

	class ShadowError < StandardError ; end
	class Shadow
		require 'fileutils'
		#include FileUtils
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
			raise ShadowError, "#{line} failed" unless $? == 0 or !@required
		end

		def exists(path)
			system("test -e #{path.exp_path}")
		end

		def ln_s(source, dest)
			unless exists(dest)
				FileUtils::ln_s(source.exp_path, dest.exp_path)
			end
		end

		def mkdir(path)
			unless exists(path)
				FileUtils::mkdir_p(path.exp_path)
			end
		end

		def install(package)
			raise ShadowError, "No installer specified for this target!" unless @installer
			puts "=> Ensuring #{package} is installed with #{@installer}"
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
