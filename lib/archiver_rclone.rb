require 'pathname'
require_relative 'command'

module Pdfsp
	module Archiver
		# Archives the source pdf to any rclone remote, e.g. in ~/.pdfsprc
		#
		#   archiver:
		#     type: rclone
		#     remote: s3scans:YOUR-BUCKET
		#
		# The remote must already be set up with `rclone config`.
		# Behaves like the original S3 archiver: spaces in the filename
		# become underscores, and if the file is already in the archive
		# the local copy is deleted (scan names are unique timestamps, so
		# the same name means the same scan).
		# Commands are passed to rclone as separate arguments (no shell),
		# so filenames containing spaces, quotes, brackets etc. are safe.
		class ArchiverRclone
			class << self
				def suitable?(settings_hash)
					return false unless settings_hash.is_a? Hash
					return false unless settings_hash['type'] == 'rclone'
					return false unless settings_hash['remote'].is_a?(String)
					return false if settings_hash['remote'].strip.empty?
					true
				end
			end

			def initialize(settings_hash, cmd: Command.new)
				@remote = settings_hash['remote'].strip.chomp('/')
				@rclone = settings_hash.fetch('rclone', 'rclone')
				@cmd = cmd
			end

			def call(source)
				if exists?(source)
					STDERR.puts "#{destination(source)} is already in the archive"
					STDERR.puts "Deleting #{source} now it is in the archive"
					source.delete
					return true
				end
				archive(source)
			rescue Errno::ENOENT
				STDERR.puts "Could not run '#{@rclone}'. Is rclone installed and on your PATH?"
				STDERR.puts "Leaving #{source} in place."
				false
			end

			# rclone moveto uploads the file, verifies it (size, plus hash
			# where the remote supports one) and only then deletes the
			# local copy.
			def archive(source)
				output, success = @cmd.call(@rclone, 'moveto', source.to_s, destination(source))
				if success
					STDERR.puts "#{source} has been moved to #{destination(source)}"
				else
					STDERR.puts "rclone failed to archive #{source}"
					STDERR.puts output
					STDERR.puts "Leaving #{source} in place."
				end
				success
			end

			# `rclone lsf` on a file path prints the name when the file exists.
			# On S3 a missing file still exits 0 (it is listed as an empty
			# "directory"), so check the printed name matches exactly.
			def exists?(source)
				output, success = @cmd.call(@rclone, 'lsf', '--files-only', destination(source))
				success && output.lines.map(&:chomp).include?(target(source))
			end

			def destination(source)
				separator = @remote.end_with?(':') ? '' : '/'
				"#{@remote}#{separator}#{target(source)}"
			end

			def target(source)
				Pathname.new(source).basename.to_s.gsub(' ', '_')
			end
		end

	end
end
