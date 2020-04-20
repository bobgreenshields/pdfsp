require 'pathname'
require_relative 'command'
require_relative 'archiver'

module Pdfsp

	class PdfspError < RuntimeError; end

	class App
		def initialize(settings:, options:, cmd: Command.new)
			@settings = settings
			@options = options
			@cmd = cmd
		end

		def pdftk_present?
			_, found = @cmd.call('which pdftk')
			found
		end

		def cloudfile
			path = Pathname.new(@settings['cloudfile']).expand_path
			exit_invalid_cloudfile_dir(path) unless directory?(path)
			path
		end

		def directory?(path)
			path.directory?
		end

		def exit_with_0
			exit(0)
		end

		def call
			exit_no_pdftk unless pdftk_present?
			cmd_strings.each do | cmd_str |
				_, success = @cmd.call(cmd_str)
				exit(80) unless success
			end
			archiver.call(source) if @options.key?(:archive)
			exit_with_0
		end

		def source
			@source ||= @options[:source]
		end

		def destdir
			return @destdir if @destdir
			if @options.key?(:cloudfile)
				exit_cloudfile_not_set unless @settings.key?('cloudfile')
				@destdir = cloudfile
			else
				@destdir = @options[:destdir] || Pathname.pwd.expand_path
			end
		end

		def archiver
			@archiver ||= Archiver.instance(@settings)
		end

		def pages
			return @pages if @pages
			@pages = @options[:pagelist]
			exit_duplicate_pages if has_duplicates?(@pages)
			exit_too_many_pages if (@pages[-1] > no_pages)
			@pages << no_pages unless @pages[-1] == no_pages
			@pages
		end

		def has_duplicates?(page_arr)
			page_arr.inject(0)  do | last, current |
				return true if current == last
				current
			end
			return false
		end

		def no_pages
			@no_pages ||= get_no_pages(source)
		end

		def esc(file)
			file.to_s.gsub(' ', '\ ')
		end

		def get_no_pages(pdf)
			result_string, _ = @cmd.call("pdftk #{esc(pdf)} dump_data | grep NumberOfPages")
			result_string.split(':')[1].strip.to_i
		end

		def page_ranges
			return @page_ranges if @page_ranges
			@page_ranges = []
			pages.inject(1) do | start, next_cut |
				@page_ranges << (start == next_cut ? start.to_s : "#{start}-#{next_cut}")
				next_cut + 1
			end
			@page_ranges
		end

		def cmd_strings
			page_ranges.map do | range |
				dest = destdir + "#{source.basename.to_s.delete_suffix('.pdf')}_#{range}.pdf"
				"pdftk #{esc(source)} cat #{range} output #{esc(dest)}"
			end
		end

		def exit_no_pdftk
			STDERR.puts "This application requires pdftk to be installed on the system."
			STDERR.puts "It does not appear to be present."
			exit(72)
		end
		
		def exit_invalid_cloudfile_dir(dir)
			STDERR.puts 'The cloudfile directory should be a valid directory'
			STDERR.puts "#{dir} is not a valid directory"
			exit(73)
		end

		def exit_cloudfile_not_set
			STDERR.puts 'The cloudfile directory has not been set in the .pdfsprc file'
			STDERR.puts 'or there is no .pdfsprc file in your home directory'
			exit(74)
		end

		def exit_duplicate_pages
			STDERR.puts "Your list of pages contains duplicates"
			STDERR.puts @options[:pagelist].map(&:to_s).join(' ')
			STDERR.puts
			STDERR.puts "Run pdfsp -h for help."
			exit(75)
		end

		def exit_too_many_pages
			STDERR.puts "Your list of pages contains numbers higher than the number of pages in the pdf."
			STDERR.puts "The page list is #{@options[:pagelist].map(&:to_s).join(' ')}"
			STDERR.puts "The number of pages in the pdf is #{no_pages}"
			STDERR.puts
			STDERR.puts "Run pdfsp -h for help."
			exit(76)
		end

	end
	
end
