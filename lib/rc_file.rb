require 'pathname'
require 'yaml'

module Pdfsp
	class RCFile
		def call(rcfile)
			path = Pathname.new(rcfile)
			return {} unless rc_file_exist?(path)
			begin
				result = read_rc_file(path)
				exit_error_loading_yaml(message: "The file returned nil from the yaml", path: path) if result.nil?
				result
			rescue StandardError => e
				exit_error_loading_yaml(message: e.message, path: path)
			end
		end

		def rc_file_exist?(path)
			path.file?
		end

		def read_rc_file(path)
			YAML.load(path.read)
		end

		def exit_error_loading_yaml(message:, path:)
				STDERR.puts "There was a problem loading the config file"
				STDERR.puts path.to_s
				STDERR.puts "It should be formatted in YAML"
				STDERR.puts message.to_s
				exit(71)
		end

	end
end
