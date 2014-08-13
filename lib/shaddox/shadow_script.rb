module Shaddox
	class ShadowScript
		attr_reader :script
		def initialize(config, task_key, opts = {})
			# Initialize properties
			@installer = opts[:installer]
			@debug = opts[:debug]

			@config = config
			@cast_tasks = []

			# Generate script
			params = []
			params.push(":installer => :#{@installer}") if @installer
			params.push(":debug => #{@debug}") if @debug

			@script = %Q{
require 'shaddox'
Shaddox::Shadow.new({#{params.join(',')}}) do
	## begin generated shadow ##
			}
			add_repos
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
				raise "The task :#{task_key} could not be found. Please check your Doxfile and try again.".red
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

		## add_repos
		# Retrieves all repos from the @config and ensures their data is copied
		# to the script for use by tasks.
		def add_repos
			@script += %Q(
	@repos = {)
			@config.repos.each do |key, repo|
				@script += ":#{key} => #{repo.to_source}"
			end
			@script += %Q(})
		end
	end
end
