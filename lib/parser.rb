require 'optparse'
require 'pathname'

module Pdfsp
	class Parser
		def initialize
			@options = {}
		end

		def opt_parser
			@opt_parser ||= OptionParser.new do | opts |
				opts.banner = 'Usage: pdfsp filename [options] pagelist'
				opts.on '-a', '--archive', 'Archive the original file' do @options[:archive] = nil end
				opts.on '-c', '--cloudfile', 'Output the pages to the cloudfile dir' do @options[:cloudfile] = nil end
				opts.on '-h', '--help', 'Prints this help' do puts opts; exit end
			end
		end

		def call(argv)
			args_arr = opt_parser.parse(argv)
			check_enough_args(args_arr)
			check_valid_path(args_arr[0])
			check_is_pdf(args_arr[0])
			@options[:source] = Pathname.new(args_arr[0]).expand_path
			check_pagelist_are_integers(args_arr[1..-1])
			@options[:pagelist] = args_arr[1..-1].map(&:to_i)
			@options
		end

		def check_enough_args(args_arr)
			exit_not_enough_args if args_arr.length < 2
		end

		def check_valid_path(filename)
			exit_invalid_filename(filename) unless Pathname.new(filename).exist?
		end

		def check_is_pdf(filename)
			path = Pathname.new(filename)
			exit_not_a_pdf(path.to_s) unless path.extname.downcase == '.pdf'
		end

		def integer_test
			@integer_test ||= /^\s*\d+\s*$/
		end

		def pages_are_integers?(page_arr)
			page_arr.reject do | page |
				integer_test.match(page)
			end.empty?
		end

		def check_pagelist_are_integers(page_arr)
			exit_pagelist_not_integers unless pages_are_integers?(page_arr)
		end

		def exit_not_enough_args
			STDERR.puts 'pdfsp needs at least two arguments (in addition to any options)'
			STDERR.puts 'The first should be a pdf filename to split'
			STDERR.puts 'The rest are page numbers after which to split'
			exit(65)
		end

		def exit_invalid_filename(filename)
			STDERR.puts 'The first argument should be a pdf file to split'
			STDERR.puts "#{filename} is not a file that exists"
			exit(66)
		end

		def exit_not_a_pdf(filename)
			STDERR.puts 'The first argument should be a pdf file to split'
			STDERR.puts "#{filename} is not a pdf.  It should end in .pdf"
			exit(67)
		end

		def exit_pagelist_not_integers
			STDERR.puts 'The second argument onwards should be the list of pages to split after'
			STDERR.puts "They should all be integers but they weren't"
			exit(68)
		end
		
	end
	
end
