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

	class PdfspError < StandardError; end

	class App
		def initialize(cmd: Command.new)
			@cmd = cmd
		end

		def pdftk_present?
			_, found = @cmd.call('which pdftk')
			found
		end

		def call(arg_arr)
			@arg_arr = arg_arr
			exit_no_pdftk unless pdftk_present?
			exit_not_enough_args unless arg_arr.length > 1
			@pdf = Pathname.new(arg_arr[0])
			exit_not_a_pdf unless @pdf.extname == '.pdf'
			exit_pdf_not_exist unless @pdf.exist?
			exit_pages_not_integers unless pages_are_integers?(arg_arr)
			exit_duplicate_pages if has_duplicates?(pages)
		end

		def pages_are_integers?(arg_arr)
			test = /^\s*\d+\s*$/
			arg_arr[1..-1].reject do | page |
				test.match(page)
			end.length == 0
		end

		def has_duplicates?(page_arr)
			page_arr.inject(0)  do | last, current |
				return true if current == last
				current
			end
			return false
		end

		def pages
			@pages ||= get_pages(@arg_arr)
		end

		def get_pages(arg_arr)
			arg_arr[1..-1].map(&:strip).map(&:to_i).sort
		end

		def ranges(page_cuts)
			result_arr = []
			page_cuts.inject(1) do | start, next_cut |
				result_arr << (start == next_cut ? start.to_s : "#{start}-#{next_cut}")
				next_cut + 1
			end
			result_arr
		end

		def get_no_pages(pdf)
			result_string, _ = @cmd.call("pdftk #{pdf} dump_data | grep NumberOfPages")
			result_string.split(':')[1].strip.to_i
		end

		def exit_no_pdftk
			STDERR.puts NO_PDFTK
			exit(67)
		end

		def exit_not_enough_args
			STDERR.puts "pdfsp was not called with enough arguments.  It must have at least two"
			STDERR.puts
			STDERR.puts HELP
			exit(68)
		end

		def exit_not_a_pdf
			STDERR.puts "#{@pdf} is not a pdf - it doesn't end in .pdf"
			STDERR.puts
			STDERR.puts "run pdfsp with no arguments for help."
			exit(69)
		end

		def exit_pdf_not_exist
			STDERR.puts "#{@pdf} does not exist"
			STDERR.puts
			STDERR.puts "run pdfsp with no arguments for help."
			exit(70)
		end

		def exit_pages_not_integers
			STDERR.puts "Your list of pages contains items that are not numbers"
			STDERR.puts @arg_arr[1..-1].map(&:strip).join(" ")
			STDERR.puts
			STDERR.puts "run pdfsp with no arguments for help."
			exit(71)
		end

		def exit_duplicate_pages
			STDERR.puts "Your list of pages contains duplicates"
			STDERR.puts pages.map(&:to_s).join(' ')
			STDERR.puts
			STDERR.puts "run pdfsp with no arguments for help."
			exit(72)
		end

	end
end
