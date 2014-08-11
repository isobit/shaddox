module Shaddox
	class Task
		attr_accessor :block, :deps
		def initialize(block, deps)
			@block = block
			@deps = [deps].flatten
		end

		def to_source
			require 'sourcify'
			if @block
				@block.to_source(:strip_enclosure => true)
			else
				"# Empty block #"
			end
		end
	end
end
