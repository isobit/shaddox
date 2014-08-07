module Shaddox
	class ShadowScript
		attr_reader :script
		def initialize(config, target, task_key)
			@config = config
			@target = target
			@cast_tasks = []
			@script = %Q{require 'shaddox/shadow'
			Shadow.new(:pm => #{target.installer}) do
				## begin generated shadow ##
			}
			cast(task_key)
			@script += %Q{
				## end generated shadow ##
			end}
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
	class RunError < StandardError ; end
	class Shadow
		def initalize(options, &block)
			@installer = options[:installer]
			@required = true
			instance_eval(&block)
		end

		def optional(&block)
			@required = false
			instance_eval(&block)
			@required = true
		end

		def sh(command, args = nil)
			line = "#{command}"
			line += " #{args.join(" ")}" if args
			system(command, *args)
			if $? != 0 and @required
				raise RunError, "#{line} failed"
			end
		end

		def install(package)
			puts "Installing #{package} using #{@installer}"
		end
	end
end
