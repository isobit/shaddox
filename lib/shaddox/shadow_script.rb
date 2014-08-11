module Shaddox
	class ShadowScript
		attr_reader :script
		def initialize(config, task_key, target, opts = {})
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

			@config = config
			@cast_tasks = []
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
		def cast(task_key)
			puts task_key
			task = @config.tasks[task_key]
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
