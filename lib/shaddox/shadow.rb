class String
	def exp_path
		File.expand_path(self)
	end
end

module Shaddox

	class Shadow
		require 'fileutils'
		#include FileUtils
		def initialize(options, &block)
			@verbose = options[:verbose] || true
			@installer = options[:installer]
			@tmppath = options[:tmppath] || '/tmp/shaddox/'
			@required = true
			instance_eval(&block)
		end

		def warn(msg)
			puts msg.yellow
		end

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def sh(command, args = nil)
			line = "#{command}"
			line += " #{args.join(" ")}" if args
			puts "=> Running '#{line}' in '#{Dir.pwd}'" if @verbose
			system(command, *args)
			raise "#{line} failed" unless $? == 0 or !@required
		end

		def cd(path, &block)
			current_path = Dir.pwd
			FileUtils.cd(path.exp_path)
			instance_eval(&block)
			FileUtils.cd(current_path)
		end

		def exists(path)
			system("test -e #{path.exp_path}")
		end

		def ln_s(source, dest, opts = [])
			puts "=> Linking '#{source}' to '#{dest}'" if @verbose
			FileUtils::ln_s(source.exp_path, dest.exp_path, opts)
		end

		def mkdir(path)
			puts "=> Ensuring directory '#{path}' exists" if @verbose
			FileUtils::mkdir_p(path.exp_path)
		end

		def install(package)
			raise "No installer specified for this target!" unless @installer
			puts "=> Ensuring #{package} is installed with #{@installer}" if @verbose
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
