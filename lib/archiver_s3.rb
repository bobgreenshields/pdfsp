require 'pathname'
require 'aws-sdk-s3'

module Pdfsp
	module Archiver
		class ArchiverS3
			class << self
				def suitable?(settings_hash)
					return false unless settings_hash.is_a? Hash
					return false unless settings_hash.key?('type')
					return false unless settings_hash['type'] == 's3'
					return false unless settings_hash.key?('access_key_id')
					return false unless settings_hash.key?('secret_access_key')
					return false unless settings_hash.key?('bucket')
					true
				end
			end

			def initialize(settings_hash)
				@access_key_id = settings_hash['access_key_id']
				@secret_access_key = settings_hash['secret_access_key']
				@bucket_name = settings_hash['bucket']
			end

			def call(source)
				upload(source)
				if exists?(source)
					STDERR.puts "Deleting #{source} now it is in the archive"
					source.delete
				end
			end

			def upload(source)
				obj = bucket.object(target(source))
				if obj.exists?
					STDERR.puts "#{target(source)} is already in the archive"
				else
					obj.upload_file(source.to_s)
					STDERR.puts "#{target(source)} has been uploaded"
				end
			end

			def exists?(source)
				bucket.object(target(source)).exists?
			end

			def target(source)
				source.basename.to_s.gsub(' ', '_')
			end

			def bucket
				@bucket ||= get_bucket
			end

			def get_bucket
				credentials = Aws::Credentials.new(@access_key_id, @secret_access_key)
				s3 = Aws::S3::Resource.new(region: 'eu-west-2', credentials: credentials)
				s3.bucket(@bucket_name)
			end
		end
		
	end
	
end
