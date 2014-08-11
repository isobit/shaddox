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

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def sh(command, args = nil)
			line = "#{command}"
			line += " #{args.join(" ")}" if args
			info "Running '#{line}' in '#{Dir.pwd}'", 1 if @verbose
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

		def ln_s(source, dest, opts = {})
			info "Linking '#{source}' to '#{dest}'", 1 if @verbose
			FileUtils::ln_s(source.exp_path, dest.exp_path, opts)
		end

		def mkdir(path)
			info "Ensuring directory '#{path}' exists", 1 if @verbose
			FileUtils::mkdir_p(path.exp_path)
		end

		def repo_clone(repo_key, path)
			repo = @repos[repo_key]
			cd path do
				case repo.vcs
				when :git
					sh "git clone #{repo.url}"
				end
			end
		end

		def install(package)
			unless @installer
				warn "No package manager is defined for this target.", 1
				puts "-------------------"
				require 'highline/import'
				choose do |menu|
					menu.prompt = "Please select a package manager to use:"

					menu.choice(:apt) { @installer = :apt }
					menu.choice(:brew) { @installer = :brew }
				end
				puts "-------------------"
			end
			raise "No installer specified for this target!" unless @installer
			info "Ensuring #{package} is installed with #{@installer}", 1 if @verbose
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
