module Shaddox
	class Task
		attr_accessor :block, :deps
		def initialize(block, deps)
			@block = block
			@deps = [deps].flatten
		end
	end
end
