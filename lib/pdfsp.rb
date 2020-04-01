require 'pathname'
require_relative 'command'

module Pdfsp

	NO_PDFTK = <<-DOC
This application requires pdftk to be installed on the system.

It does not appear to be present.
DOC

	class PdfspError < StandardError; end

	class App
		def initialize(cmd: Command.new)
			@cmd = cmd
		end

		def check_for_pdftk
			_, found = @cmd.call('which pdftk')
			found
		end

		def call(arg_arr)
			unless check_for_pdftk
				puts NO_PDFTK
				exit(67)
			end
			@pdf, page_arr = process_args(arg_arr)
		end

		def process_args(arg_arr)
			pdf = Pathname.new(arg_arr[0])
			pages_arr = arg_arr[1..-1].map(&:to_i).sort
			return pdf, pages_arr
		end





		def get_no_pages(pdf)
			result_string, _ = @cmd.call("pdftk #{pdf} dump_data | grep NumberOfPages")
			result_string.split(':')[1].strip.to_i
		end

		
	end
end
