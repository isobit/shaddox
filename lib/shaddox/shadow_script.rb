module Shaddox
	class ShadowScript
		attr_reader :script
		def initialize(config, target, task_key)
			@config = config
			@target = target
			@cast_tasks = []
			@script = %Q{
require 'shaddox'
Shaddox::Shadow.new(:installer => :#{target.installer}) do
	## begin generated shadow ##
			}
			cast(task_key)
			@script += %Q{
	## end generated shadow ##
end
			}
		end
		def cast(task_key)
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
