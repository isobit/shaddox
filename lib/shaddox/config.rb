module Shaddox
	class Config

		# Init ==============================================

		attr_accessor :tasks

		def initialize(doxfile, opts = {})
			doxfile = './Doxfile' unless doxfile
			if !File.exists?(doxfile)
				puts "Doxfile could not be found.".red
				exit(1)
			end

			@tasks = Hash.new
			@pvr = Provisioner.new(opts)

			instance_eval(File.read(doxfile), doxfile)
		end

		# Methods ============================================

		def invoke(task_key)
			begin
				task = @tasks[task_key.to_sym]
				return if task.done
				task.deps.each { |dep| invoke(dep) }
				info "[#{task_key}] Starting..."
				@pvr.run(task.block)
				task.done = true
				info "[#{task_key}] Done".green
			rescue => e
				err "[#{task_key}] Failed".red
				puts e.message.red
				e.backtrace.each { |line| puts line }
			end
		end

		## DSL Methods ##

		# ### Add a task
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
