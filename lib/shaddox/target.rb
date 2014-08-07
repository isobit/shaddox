module Shaddox
	class Target
		def new_shell_actor
			raise "new_actor method must be implemented by Target subclass"
		end
		def deploy(shadow_script)
			lockfile = '/tmp/shaddox.lock'
			new_shell_actor do
				unlocked = run "mkdir #{lockfile}", "Creating lock..."
				raise "Shaddox is already running on this machine. Try again later." unless unlocked
				begin
					ruby_installed = exec 'type ruby >/dev/null 2>&1'
					raise "Ruby is required to use shaddox. Please install it manually." unless ruby_installed
					gem_installed = exec 'type gem >/dev/null 2>&1'
					raise "Gem is required to use shaddox. Please install it manually." unless gem_installed
					if !exec('gem list shaddox -i')
						run "gem install shaddox", "Installing shaddox..."
					end
					shaddox_installed = exec 'gem list shaddox -i'
					raise "Shaddox could not be automatically installed. Please install manually with 'gem install shaddox'." unless shaddox_installed
					puts "TODO: Do shadow deployment here!"
				ensure
					run("rm -r #{lockfile}", "Removing lock...") unless !exec("test -e #{lockfile}")
				end
			end
		end
	end

	class ShellActor
		def initialize(&block)
			instance_eval(&block)
		end
		def run(command, msg = nil, error_msg = "Command failed, aborting!")
			info = command
			info = msg if msg
			puts "=> #{info}"
			result = exec(command)
			raise error_msg if result == nil
			result
		end
		def exec
			raise "exec method must be implemented by Actor subclass"
		end
	end

	class Localhost < Target
		def new_shell_actor(&block)
			LocalActor.new(&block)
		end
		def installer
			:apt
		end
		class LocalActor < ShellActor
			def exec(command)
				system(command)
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
		def new_shell_actor(&block)
			SSHActor.new(host, user, ssh, &block)
		end
		class SSHActor < ShellActor
			def initialize(host, user, ssh_opts, &block)
				Net::SSH.start(host, user, ssh_opts) do |ssh|
					@ssh = ssh
					super(&block)
				end
			end
			def exec(command)
				#success, stdout, stderr, exit_code, exit_signal = nil
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
		end
	end
end
