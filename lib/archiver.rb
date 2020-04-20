require_relative 'archiver_null.rb'
require_relative 'archiver_s3.rb'

module Pdfsp
	module Archiver
		def Archiver.instance(settings)
			return ArchiverNull.new(nil) unless settings.key?('archiver')
			archiver_settings = settings['archiver']
			return ArchiverS3.new(archiver_settings) if ArchiverS3.suitable?(archiver_settings)
			return ArchiverNull.new(archiver_settings)
		end
	end
	
end
