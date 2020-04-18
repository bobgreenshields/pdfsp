require_relative '../lib/parser'

include Pdfsp

describe Parser do
	let(:parser) { Parser.new }

	describe '#check_enough_args' do
		context 'with less than 2 arguments' do
			let(:args) { ['filename'] }
			it 'calls #exit_not_enough_args' do
				expect(parser).to receive(:exit_not_enough_args)
				parser.check_enough_args(args)
			end
		end
		context 'with 2 or more args' do
			let(:args) { ['filename', '5'] }
			it 'does not call #exit_not_enough_args' do
				expect(parser).not_to receive(:exit_not_enough_args)
				parser.check_enough_args(args)
			end
		end
	end
			
	describe '#check_is_pdf' do
		context 'when the first arg does not end in .pdf' do
			let(:args) { 'filename.txt' }
			it 'calls #exit_not_a_pdf' do
				expect(parser).to receive(:exit_not_a_pdf)
				parser.check_is_pdf(args)
			end
		end
		context 'when the first arg does end in .pdf' do
			let(:args) { 'filename.pdf' }
			it 'does not call #exit_not_a_pdf' do
				expect(parser).not_to receive(:exit_not_a_pdf)
				parser.check_is_pdf(args)
			end
		end
	end
			
	describe '#check_pagelist_are_integers' do
		context 'when the list has non-integers' do
			let(:args) { %w(1 2 rf 4 8) }
			it 'calls #exit_pagelist_not_integers' do
				expect(parser).to receive(:exit_pagelist_not_integers)
				parser.check_pagelist_are_integers(args)
			end
		end
		context 'when the list has only integers' do
			let(:args) { ['1', '  2 ', ' 3', '289'] }
			it 'does not call #exit_pagelist_not_integers' do
				expect(parser).not_to receive(:exit_pagelist_not_integers)
				parser.check_pagelist_are_integers(args)
			end
		end
	end

	describe '#call' do
		context 'with options of -fa' do
			let(:args) { ['filename.pdf', '-ca', ' 2', '5'] }
			it 'returns a hash with the correct keys' do
				allow(parser).to receive(:check_valid_path).and_return(true)
				result = parser.call(args)
				expect(result.key?(:archive)).to be_truthy
				expect(result.key?(:cloudfile)).to be_truthy
				expect(result[:pagelist]).to eql [2,5]
				expect(result[:source].to_s).to eql (Pathname.pwd + 'filename.pdf').to_s
			end
		end
		context 'with a filename as the first arg' do
			let(:args) { ['filename.pdf', '-ca', ' 2', '5'] }
			it 'returns the correct pathname in the :source key' do
				allow(parser).to receive(:check_valid_path).and_return(true)
				result = parser.call(args)
				expect(result[:source].to_s).to eql (Pathname.pwd + 'filename.pdf').to_s
			end
		end
		context 'with integers as the last args' do
			let(:args) { ['filename.pdf', '-ca', ' 2', '5'] }
			it 'returns an array of integers in the :pagelist key' do
				allow(parser).to receive(:check_valid_path).and_return(true)
				result = parser.call(args)
				expect(result[:pagelist]).to eql [2,5]
			end
		end
	end
	
end
