require 'pathname'
require_relative 'command'

module Pdfsp

	NO_PDFTK = <<-DOC
This application requires pdftk to be installed on the system.

It does not appear to be present.
DOC

NOT_ENOUGH_ARGS = <<-DOC
pdfsp needs to be run with a file name and then a list of pages to split after
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
			exit_not_enough_args unless arg_arr.length > 1
			exit_no_pdftk unless pdftk_present?
			@pdf, page_arr = process_args(arg_arr)
		end

		def process_args(arg_arr)
			pdf = Pathname.new(arg_arr[0])
			pages_arr = arg_arr[1..-1].map(&:to_i).sort
			return pdf, pages_arr
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
			puts NO_PDFTK
			exit(67)
		end

		def exit_not_enough_args
			puts NOT_ENOUGH_ARGS
			exit(68)
		end
		
	end
end
