module Shaddox
	class Repo
		attr_reader :url, :branch, :vcs
		def initialize(info)
			@info = info
			@url = info[:url]
			@branch = info[:branch] || 'master'
			@vcs = info[:vcs] || :git
		end

		def to_source
			"Shaddox::Repo.new(#{@info.inspect})"
		end
	end
end
