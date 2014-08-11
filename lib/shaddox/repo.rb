module Shaddox
	class Repo
		attr_reader :info
		def initialize(info)
			@info = info
		end

		def to_source
			"Shaddox::Repo.new(#{@info.inspect})"
		end
	end
end
