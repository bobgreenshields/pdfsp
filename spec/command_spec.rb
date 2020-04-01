require_relative '../lib/command'

include Pdfsp

describe Command do
	describe '#call' do
		it 'returns success as the second result' do
			_, success = Command.new.call('which ruby')
			expect(success).to be_truthy
		end
	end
end
