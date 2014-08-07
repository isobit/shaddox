require 'shaddox/shadow'
			Shadow.new(:pm => apt) do
				## begin generated shadow ##
			
				## foo ##
				sh("echo 'foo'")
			
				## foobar ##
				sh("echo 'bar'")
			
				## install ##
				install("zsh")
			
				## end generated shadow ##
			end