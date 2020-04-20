
module Pdfsp
	module Archiver
		class ArchiverNull
			def initialize(settings_hash)
			end

			def call(source)
				STDERR.puts 'No archiver has been set up in the .pdfsprc config file'
				STDERR.puts "Leaving #{source} in place."
			end
		end
		
	end
end
