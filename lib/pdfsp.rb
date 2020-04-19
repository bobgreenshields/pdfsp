require 'pathname'
require_relative 'command'

module Pdfsp

	NO_PDFTK = <<-DOC
This application requires pdftk to be installed on the system.

It does not appear to be present.
DOC

	HELP = <<-DOC
pdfsp needs to be run with a file name and then a list of pages to split after.
e.g.

$ pdfsp ~/scan.pdf 1 3

This will split the scan.pdf after the end of page 1, then after the end of page 3 and then to the end

i.e. pages 1, 2-3, 4-end

it will output these pdfs as ~/scan_1.pdf scan_2.pdf and scan_3.pdf
DOC

	class PdfspError < RuntimeError; end

	class App
		def initialize(cmd: Command.new)
			@cmd = cmd
		end

		def pdftk_present?
			_, found = @cmd.call('which pdftk')
			found
		end

		def call(arg_arr)
			# arg_arr.each { |arg| puts arg }
			STDERR.puts HELP if arg_arr.length == 0
			exit_no_pdftk unless pdftk_present?
			extract_args(arg_arr)
			@ranges = ranges(@pages)
			# puts "pdf is #{@pdf}"
			# puts "dest dir is #{@dest_dir}"
			# puts "number of pages is #{no_pages}"
			# puts "page list is " + @pages.map(&:to_s).join(" ")
			# puts "range list is " + @ranges.map(&:to_s).join(" ")
			# puts "cmds are:"
			# cmd_strings.each { |cmd| puts cmd }
			cmd_strings.each do | cmd_str |
				_, success = @cmd.call(cmd_str)
				exit(78) unless success
			end
			exit(0)
		end

		def esc(file)
			file.to_s.gsub(' ', '\ ')
		end

		def cmd_strings
			@ranges.map do | range |
				dest = @dest_dir + "#{@pdf.basename.to_s.delete_suffix('.pdf')}_#{range}.pdf"
				"pdftk #{esc(@pdf)} cat #{range} output #{esc(dest)}"
			end
		end

		def extract_args(arg_arr)
			exit_not_enough_args unless arg_arr.length > 1
			next_args = set_pdf(arg_arr)
			next_args = set_dest_dir(next_args)
			next_args = set_pages(next_args)
		end

		def set_pdf(arg_arr)
			@pdf = Pathname.new(arg_arr[0]).expand_path
			exit_not_a_pdf unless @pdf.extname == '.pdf'
			exit_pdf_not_exist unless @pdf.exist?
			arg_arr[1..-1]
		end

		def set_dest_dir(arg_arr)
			exit_not_enough_args unless arg_arr.length > 0
			if integer_test.match(arg_arr[0])
				@dest_dir = Pathname.pwd.expand_path
				arg_arr
			else
				@dest_dir = Pathname.new(arg_arr[0])
				exit_dest_not_exist unless @dest_dir.exist?
				exit_dest_not_dir unless @dest_dir.directory?
				@dest_dir = @dest_dir.expand_path
				arg_arr[1..-1]
			end
		end

		def set_pages(arg_arr)
			exit_not_enough_args unless arg_arr.length > 0
			exit_pages_not_integers unless pages_are_integers?(arg_arr)
			@pages = get_pages(arg_arr)
			exit_not_enough_args unless arg_arr.length > 0
			exit_duplicate_pages if has_duplicates?(@pages)
			exit_too_many_pages if (@pages[-1] > no_pages)
			@pages << no_pages unless @pages[-1] == no_pages
			[]
		end

		def integer_test
			@integer_test ||= /^\s*\d+\s*$/
		end

		def pages_are_integers?(arg_arr)
			arg_arr[1..-1].reject do | page |
				integer_test.match(page)
			end.length == 0
		end

		def has_duplicates?(page_arr)
			page_arr.inject(0)  do | last, current |
				return true if current == last
				current
			end
			return false
		end

		def get_pages(arg_arr)
			arg_arr.map(&:strip).map(&:to_i).sort
		end

		def ranges(page_cuts)
			result_arr = []
			page_cuts.inject(1) do | start, next_cut |
				result_arr << (start == next_cut ? start.to_s : "#{start}-#{next_cut}")
				next_cut + 1
			end
			result_arr
		end

		def no_pages
			@no_pages ||= get_no_pages(@pdf)
		end

		def get_no_pages(pdf)
			result_string, _ = @cmd.call("pdftk #{esc(pdf)} dump_data | grep NumberOfPages")
			result_string.split(':')[1].strip.to_i
		end

		def exit_no_pdftk
			STDERR.puts NO_PDFTK
			exit(67)
		end

		def exit_not_enough_args
			STDERR.puts "pdfsp was not called with enough arguments."
			STDERR.puts "If called without a destination dir it needs two."
			STDERR.puts "If called with a destination dir it needs three."
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(68)
		end

		def exit_not_a_pdf
			STDERR.puts "The first argument should be a pdf to split."
			STDERR.puts "#{@pdf} is not a pdf - it doesn't end in .pdf"
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(69)
		end

		def exit_pdf_not_exist
			STDERR.puts "The first argument should be a pdf to split."
			STDERR.puts "#{@pdf} does not exist"
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(70)
		end

		def exit_dest_not_exist
			STDERR.puts "If the second argument is not the start of the page list"
			STDERR.puts "it should be the destination directory."
			STDERR.puts "#{@dest_dir} does not exist."
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(72)
		end

		def exit_dest_not_dir
			STDERR.puts "If the second argument is not the start of the page list"
			STDERR.puts "it should be the destination directory."
			STDERR.puts "#{@dest_dir} exists but is not a valid directory."
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(72)
		end

		def exit_pages_not_integers
			STDERR.puts "Your list of pages contains items that are not numbers"
			STDERR.puts @arg_arr[1..-1].map(&:strip).join(" ")
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(71)
		end

		def exit_duplicate_pages
			STDERR.puts "Your list of pages contains duplicates"
			STDERR.puts @pages.map(&:to_s).join(' ')
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(72)
		end

		def exit_too_many_pages
			STDERR.puts "Your list of pages contains numbers higher than the number of pages in the pdf."
			STDERR.puts "The page list is #{@pages.map(&:to_s).join(' ')}"
			STDERR.puts "The number of pages in the pdf is #{no_pages}"
			STDERR.puts
			STDERR.puts "Run pdfsp with no arguments for help."
			exit(72)
		end

	end
end
