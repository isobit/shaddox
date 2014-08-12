module Shaddox
	class Config
		attr_accessor :servers, :targets, :repos, :tasks
		def initialize(doxfile)
			doxfile = './Doxfile' unless doxfile
			if !File.exists?(doxfile)
				puts "Doxfile could not be found.".red
				exit(1)
			end

			@servers = Hash.new
			@targets = Hash.new {|hsh, key| @servers[key]}  # Fall back on @servers hash for missing targets
			@tasks = Hash.new
			@repos = Hash.new

			# :local and :localhost point to local by default
			@targets[:localhost] = Localhost.new
			@targets[:local] = :localhost

			instance_eval(File.read(doxfile), doxfile)
		end

		def explode_target(target_key)
			exploded = []
			[@targets[target_key]].flatten.each do |target|
				if target.is_a? Symbol
					exploded += explode_target(target)
				else
					exploded.push(target)
				end
			end
			exploded
		end

		def invoke(task_key, target_key, opts = {})
			explode_target(target_key).each do |target|
				raise "The target :#{target_key} could not be found. Please check your Doxfile.".red unless target
				info "Deploying to #{target_key}..."
				begin
					script_opts = {}
					script_opts[:installer] = target.installer if target.respond_to? :installer
					script = ShadowScript.new(self, task_key, script_opts)
					target.deploy(script, opts)
					info "Provisioning on :#{target_key} complete.".green
				rescue TargetError => e
					err "Provisioning on :#{target_key} failed:".red
					puts e.message.red
				rescue => e
					err "Provisioning on :#{target_key} failed:".red
					puts e.message.red
				end
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
		#	key can be bound to a list to define dependencies, like with Rake
		#	task :example => :some_dep do ...
		#	task :example => [:dep1, :dep2] do ...
		def task(arg, &block)
			if arg.is_a? Hash
				fail "Task Argument Error" if arg.size != 1
				key, deps = arg.map { |k, v| [k, v] }.first
				@tasks[key] = Task.new(block, deps)
			else
				fail "Task Argument Error" if !arg.is_a? Symbol
				@tasks[arg] = Task.new(block, [])
			end
		end

	end
end
