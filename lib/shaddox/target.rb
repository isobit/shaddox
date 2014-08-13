module Shaddox
	class TargetError < StandardError ; end
	class Target
		def new_actor
			raise "new_actor method must be implemented by Target subclass"
		end
		def deploy(shadow_script, opts)
			tmpdir = opts[:tmpdir] || '/tmp/shaddox'
			shadow_script_path = "#{tmpdir}/shadow_script.rb"
			# Everything inside this block is handled by the target's actor (typically an SSH session)
			new_actor do

				rm_tmpdir = lambda { 
					unless !exec("test -e #{tmpdir} >/dev/null")
						info "Removing #{tmpdir}", 1
						exec("rm -r #{tmpdir}")
					end
				}

				rm_tmpdir.call() if opts[:force]

				# Try to create tmpdir:
				info "Creating #{tmpdir}", 1
				unlocked = exec "mkdir #{tmpdir}"

				# Abort if the tmpdir already exists
				raise TargetError, "A shadow script is already running on this machine. Try again later." unless unlocked

				begin
					# Initial provisioning to ensure that we have everyting we need to execute a shadow script:
					ruby_installed = exec 'type ruby >/dev/null'
					raise TargetError, "Ruby is required to use shaddox. Please install it manually." unless ruby_installed
					gem_installed = exec 'type gem >/dev/null'
					raise TargetError, "Gem is required to use shaddox. Please install it manually." unless gem_installed
					shaddox_installed = lambda { exec 'gem list shaddox -i >/dev/null' }
					if shaddox_installed.call()
						info "Updating shaddox...", 1
						updated = exec "gem update shaddox", :verbose => false
						updated = exec "sudo gem update shaddox" unless updated
						warn "Shaddox could not be automatically updated. Please update it manually with 'gem update shaddox'.", 1 unless updated
					else
						info "Installing shaddox...", 1
						installed = exec "gem install shaddox", :verbose => false
						installed = exec "sudo gem install shaddox" unless installed
						warn "Shaddox could not be automatically installed. Please update it manually with 'gem update shaddox'.", 1 unless installed
					end
					unless shaddox_installed.call()
						raise TargetError, "Shaddox was not found on this target."
					end

					# Push the shadow script to tmpdir:
					info "Writing shadow script", 1
					write_file(shadow_script.script, shadow_script_path)

					# Execute the shadow script:
					info "Executing shadow script", 1
					raise TargetError, "Shadow script was not executed successfully." unless exec "ruby #{shadow_script_path}"

					rm_tmpdir.call() unless opts[:keep_tmp_dir]
				rescue Exception => e
					# Make sure the tmpdir is removed even if the provisioning fails:
					rm_tmpdir.call() unless opts[:keep_tmp_dir]
					raise e
				end
			end
		end
	end

	class Actor
		def initialize(&block)
			instance_eval(&block)
		end
		def exec(command, opts = {})
			raise "exec method must be implemented by Actor subclass"
		end
		def write_file(content, dest_path)
			raise "write_file method must be implemented by Actor subclass"
		end
	end

	class Localhost < Target
		def new_actor(&block)
			LocalActor.new(&block)
		end
		class LocalActor < Actor
			def exec(command, opts = {})
				system(command)
			end
			def write_file(content, dest_path)
				File.open(dest_path, 'w') { |f| f.write(content) }
			end
		end
	end

	class Server < Target
		include SettingContainer
		require 'net/ssh'
		# ###
		# Constructor for Server
		# @info param A hash containing the server's info. Allowed keys:
		#	:host (required)
		#	:user (required)
		#	:ssh  (required for authentication)
		#	:installer
		#
		attr_reader :host, :user, :ssh, :installer
		def initialize(info)
			@host = info[:host]
			@user = info[:user]
			@ssh = info[:ssh]
			@installer = info[:installer]
		end
		def new_actor(&block)
			SSHActor.new(host, user, ssh, &block)
		end
		class SSHActor < Actor
			def initialize(host, user, ssh_opts, &block)
				Net::SSH.start(host, user, ssh_opts) do |ssh|
					@ssh = ssh
					super(&block)
				end
			end
			def exec(command, opts = {:verbose => true})
				require 'highline/import'
				exit_code = nil
				@ssh.open_channel do |channel|
					channel.request_pty do |c, success|
						raise "SSH could not obtain a pty." unless success
						channel.exec(command)
						channel.on_data do |c_, data|
							if data =~ /\[sudo\]/ || data =~ /Password/i
								warn "Target is asking for password: ", 1
								$stdout.print data
								pass = ask("") { |q| q.echo = false }
								channel.send_data "#{pass}\n"
							else
								$stdout.print data if opts[:verbose]
							end
						end
						channel.on_request('exit-status') do |ch, data|
							exit_code = data.read_long
						end
					end
				end
				@ssh.loop
				exit_code == 0 ? true : false
			end
			def write_file(content, dest_path)
				require 'shellwords'
				exec "echo #{Shellwords.shellescape(content)} > #{dest_path}"
			end
		end
	end
end
