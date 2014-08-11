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

				rm_tmpdir = lambda { run("rm -r #{tmpdir}", "Removing temporary directory") unless !exec("test -e #{tmpdir}") }
				rm_tmpdir.call() if opts[:force]

				# Try to create tmpdir:
				unlocked = run "mkdir #{tmpdir}", "Creating temporary directory"

				# Abort if the tmpdir already exists
				raise TargetError, "Shaddox is already running on this machine. Try again later." unless unlocked

				begin
					# Initial provisioning to ensure that we have everyting we need to execute a shadow script:
					ruby_installed = exec 'type ruby >/dev/null'
					raise TargetError, "Ruby is required to use shaddox. Please install it manually." unless ruby_installed
					gem_installed = exec 'type gem >/dev/null'
					raise TargetError, "Gem is required to use shaddox. Please install it manually." unless gem_installed
					shaddox_installed = lambda { exec 'gem list shaddox -i' }
					unless shaddox_installed.call()
						run "gem install shaddox", "Installing shaddox..."
					end
					unless shaddox_installed.call()
						raise TargetError, "Shaddox could not be automatically installed. Please install manually with 'gem install shaddox'."
					end

					# Push the shadow script to tmpdir:
					puts "=> Writing shadow script"
					write_file(shadow_script.script, shadow_script_path)

					# Execute the shadow script:
					run "ruby #{shadow_script_path}", 'Executing shadow script'

					rm_tmpdir.call() unless opts[:keep_tmp_dir]
				rescue => e
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
		def run(command, msg = nil, error_msg = "Command failed, aborting!", opts = {})
			quiet = opts[:quiet] || false

			info = command
			info = msg if msg
			puts "=> #{info}" unless quiet
			result = exec(command)
			raise error_msg.red if result == nil
			return result
		end
		def exec(command)
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
			def exec(command)
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
		def initialize(info)
			# TODO: Validate info
			init_settings(info)
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
			def exec(command)
				exit_code = nil
				@ssh.open_channel do |channel|
					channel.exec(command) do |ch, success|
						return nil if !success
						ch.on_request('exit-status') do |ch, data|
							exit_code = data.read_long
						end
					end
				end
				@ssh.loop
				exit_code == 0 ? true : false
			end
			def write_file(content, dest_path)
				require 'shellwords'
				run("echo #{Shellwords.shellescape(content)} > #{dest_path}", :quiet => true)
			end
		end
	end
end
