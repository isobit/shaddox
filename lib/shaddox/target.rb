module Shaddox
	class Server
		include SettingContainer

		# ###
		# Constructor for Server
		# @info param A hash containing the server's info. Allowed keys:
		#	:address (required)
		#	:user
		#	:port
		#	:identity_file
		#	:ssh_options
		#	:installer
		#
		def initialize(info)
			# TODO: Validate info
			init_settings(info)
		end

		# ###
		# Generates the shell command to open an SSH session to this server.
		#
		def ssh_command
			args = address.dup
			args = "#{user}@#{args}" if user?
			args << " -i #{dentity_file}" if identity_file?
			args << " -p #{port}" if port?
			args << " #{ssh_options}"  if ssh_options?
			args << " -t"
			"ssh #{args}"
		end

	end
end
