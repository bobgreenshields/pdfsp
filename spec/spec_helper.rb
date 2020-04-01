require 'pathname'

class CmdDbl
	attr_reader :calls

	def initialize
		@calls = []
	end

	def call(command_str)
		@calls << command_str
		true
	end
end
