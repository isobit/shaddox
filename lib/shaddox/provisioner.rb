class String
	def parent
		File.split(self)[0]
	end
end

module Shaddox

	class Provisioner

		require 'fileutils'

		# Init ====================================================

		def initialize(block, opts = {:verbose => false})
			@verbose = opts[:verbose]
			@required = true
			instance_eval(&block)
		end

		# Methods =================================================

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def exists(path)
			system("test -e #{path}")
		end

		def exists_d(path)
			system("test -d #{path}")
		end

		def exists_f(path)
			system("test -f #{path}")
		end

		def exec(command, args = nil)
			cmd = "#{command}"
			cmd += " #{args.join(" ")}" if args
			info "Running '#{cmd}' in '#{Dir.pwd}'", 1 if @verbose
			system(cmd)
			raise "'#{cmd}' failed" unless $? == 0 or !@required
		end

		def cd(path, &block)
			mkdir(path)
			FileUtils.cd(path) do
				instance_eval(&block)
			end
		end

		def ln_s(source, dest, opts = {})
			mkdir(source.parent)
			mkdir(dest.parent)
			Dir.glob(source).each { |src|
				info "Linking '#{src}' to '#{dest}'", 1 if @verbose
				FileUtils::ln_s(src, dest, opts)
			}
		end

		def mkdir(path)
			info "Ensuring directory '#{path}' exists", 1 if @verbose
			FileUtils::mkdir_p(path)
		end

		def availiable?(cmd)
			exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
			ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
				exts.each { |ext|
					exe = File.join(path, "#{cmd}#{ext}")
					return true if File.executable?(exe) && !File.directory?(exe)
				}
			end
			return false
		end

		def install(package)
			@installer ||= Installer.autodetect(self);
			info "Ensuring #{package} is installed", 1 if @verbose
			@installer.install(package)
		end
	end
end
