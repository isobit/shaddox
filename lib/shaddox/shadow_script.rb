module Shaddox
	class ShadowScript
		attr_reader :script
		def initialize(config, task_key, target, opts = {})

			# Get target's specified installer:
			@installer = opts[:installer] || target.installer if target.respond_to? :installer
			unless @installer
				puts "No package manager is defined for this target.".yellow
				require 'highline/import'
				choose do |menu|
					menu.prompt = "Please select a package manager to use:"

					menu.choice(:apt) { @installer = :apt }
					menu.choice(:brew) { @installer = :brew }
				end
			end

			# Initialize properties
			@config = config
			@cast_tasks = []

			# Generate script
			@script = %Q{
require 'shaddox'
Shaddox::Shadow.new(:installer => :#{@installer}) do
	## begin generated shadow ##
			}
			cast(task_key)
			@script += %Q{
	## end generated shadow ##
end
			}
		end

		## cast
		# Retrieves a task from the @config and ensures all of its dependencies
		# have been added to the script before adding itself. Tasks are only cast
		# once to elimate redundency.
		def cast(task_key)
			task = @config.tasks[task_key]
			if !task
				raise "The task :#{task_key} could not be found. Please check your Doxfile and try again."
			end
			task.deps.each do |dep_key|
				cast(dep_key) if !@cast_tasks.include? dep_key
			end
			@script += %Q{
	## #{task_key} ##
	#{task.to_source}
			}
			@cast_tasks.push(task_key)
		end
	end
end
