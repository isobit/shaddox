module Shaddox
	class Config
		attr_accessor :servers, :targets, :repos, :tasks
		def initialize(doxfilename = "Doxfile")
			if !File.exists?(doxfilename)
				puts "Doxfile could not be found."
				exit(1)
			end

			@servers = Hash.new
			@targets = Hash.new {|hsh, key| @servers[key]}  # Fall back on @servers hash for missing targets
			@tasks = Hash.new
			@repos = Hash.new

			## Defaults ##
			self.target :script, Script.instance

			instance_eval(File.read(doxfilename), doxfilename)
		end

		def explode_target(targetkey)
			exploded = []
			[@targets[targetkey]].flatten.each do |target|
				if target.is_a? Symbol
					exploded += explode_target(target)
				else
					exploded.push(target)
				end
			end
			exploded
		end

		def invoke(taskkey, targetkey)
			package = @packages[packagekey]
			explode_target(targetkey).each do |target|
				package.invoke(target)
			end
		end

		## DSL Methods ##

		# ### Add a server
		# info: A hash containing the server's info. Allowed keys:
		#	:address (required)
		#	:user
		#	:port
		#	:identity_file
		#	:ssh_options
		def server(key, info)
			@servers[key] = Server.new(info)
		end

		# ### Add a target
		# linked_target: A symbol or Array of symbols representing
		#	the other targets/servers that this target invokes
		def target(key, linked_target)
			@targets[key] = linked_target
		end

		# ### Add a repo
		# info: A hash containing the repo's info. Allowed keys:
		#	:repository (required)
		#	:branch
		def repo(key, info)
			@repos[key] = Repo.new(info)
		end

		# ### Add a package
		# blk: A block of code to be executed in the context of the target[s]
		#	specified when running Shaddox
		def package(key, &blk)
			@packages[key] = Package.new(self, &blk)
		end

	end
end
