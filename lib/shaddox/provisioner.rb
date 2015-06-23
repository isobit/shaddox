class String
	def exp_path
		File.expand_path(self)
	end
	def parent
		File.split(self)[0]
	end
end

module Shaddox

	class Provisioner

		require 'fileutils'

		# Init ====================================================

		def initialize(opts = {:verbose => false})
			@verbose = opts[:verbose]
			@required = true
		end

		def self.run(block)
			instance_eval(&block) unless !block
		end

		# Methods =================================================

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def exists(path)
			system("test -e #{path.exp_path}")
		end

		def exists_d(path)
			system("test -d #{path.exp_path}")
		end

		def exists_f(path)
			system("test -f #{path.exp_path}")
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
			FileUtils.cd(path.exp_path) do
				instance_eval(&block)
			end
		end

		def ln_s(source, dest, opts = {})
			mkdir(dest.exp_path.parent)
			Dir.glob(source.exp_path).each { |src|
				info "Linking '#{src.exp_path}' to '#{dest.exp_path}'", 1 if @verbose
				FileUtils::ln_s(src, dest.exp_path, opts)
			}
		end

		def mkdir(path)
			info "Ensuring directory '#{path}' exists", 1 if @verbose
			FileUtils::mkdir_p(path.exp_path)
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
