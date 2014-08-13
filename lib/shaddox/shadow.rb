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
			@debug = options[:debug] || true # TODO: change to false for actual release
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
			exec(line, :verbose => true)
		end

		def exec(command, opts = {:verbose => false})
			info "Running '#{command}' in '#{Dir.pwd}'", 1 if opts[:verbose] or @debug
			system(command)
			raise "#{line} failed" unless $? == 0 or !@required
		end

		def cd(path, &block)
			mkdir(path)
			FileUtils.cd(path.exp_path) do
				instance_eval(&block)
			end
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

		def ln_s(source, dest, opts = {})
			ensure_parent_dir(source)
			ensure_parent_dir(dest)
			info "Linking '#{source.exp_path}' to '#{dest.exp_path}'", 1 if @debug
			FileUtils::ln_s(source.exp_path, dest.exp_path, opts)
		end

		def mkdir(path)
			info "Ensuring directory '#{path}' exists", 1 if @debug
			FileUtils::mkdir_p(path.exp_path)
		end

		def ensure_parent_dir(path)
			dir, base = File.split(path.exp_path)
			mkdir(dir)
		end

		def ensure_git()
			unless @git_installed
				install 'git'
				@git_installed = true
			end
		end

		def repo_deploy(repo_key, deploy_path, opts ={}, &in_deploy_path_block)
			keep_releases = opts[:keep_releases] || 5
			repo = @repos[repo_key]

			ensure_git()
			ensure_parent_dir(deploy_path)
			deploy_path = deploy_path.exp_path

			cd deploy_path do

				# Get the current release number
				release = 0
				cd 'releases' do
					current_max = Dir.entries('.').select { |e| e =~ /\d+/ }.max
					release = current_max.to_i + 1 if current_max
				end

				# Make a new release dir
				release_path = "./releases/#{release}"

				case repo.vcs
				when :git
					# Clone/update repo in vcs:
					info 'Updating the repository', 1 if @debug
					if exists_d('vcs')
						cd 'vcs' do
							exec "git fetch #{repo.url} #{repo.branch}:#{repo.branch} --force"
						end
					else
						exec "git clone #{repo.url} vcs --bare"
					end
					exec "git clone ./vcs #{release_path} --recursive --branch #{repo.branch}"
				end

				# Link shared paths
				info 'Linking shared paths', 1 if @debug
				repo.shared.each do |shared_path|
					ln_s "./shared/#{shared_path}", "#{release_path}/#{shared_path}"
				end

				# Link ./current to the latest release
				info 'Linking current to latest release', 1 if @debug
				ln_s release_path, './current'
			end

			cd deploy_path, &in_deploy_path_block if block_given?
		end

		def install(package)
			unless @installer
				# TODO: Try to autodetect package manager
				warn "No installer is specified for this target.", 1
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
			info "Ensuring #{package} is installed with #{@installer}", 1 if @debug
			package_installed = lambda { system("type #{package} >/dev/null 2>&1") }
			unless package_installed.call()
				case @installer
				when :apt
					exec "sudo apt-get install -y #{package}"
				when :brew
					exec "brew install #{package}"
				end
			end
			raise "#{package} could not be installed." unless package_installed.call()
		end
	end
end
