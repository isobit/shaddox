module Shaddox
	class Task
		attr_accessor :block, :deps, :done
		def initialize(block, deps)
			@block = block
			@deps = [deps].flatten
			@done = false
		end
	end
end
