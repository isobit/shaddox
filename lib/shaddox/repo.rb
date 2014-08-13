module Shaddox
	class Repo
		attr_reader :url, :branch, :vcs, :shared
		def initialize(info)
			@info = info
			@url = info[:url]
			@branch = info[:branch] || 'master'
			@vcs = info[:vcs] || :git
			@shared = [info[:shared]].flatten || []
		end

		def to_source
			"Shaddox::Repo.new(#{@info.inspect})"
		end
	end
end
