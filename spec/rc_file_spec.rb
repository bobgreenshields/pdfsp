require_relative '../lib/rc_file'

include Pdfsp

describe RCFile do
	let(:rcf) { RCFile.new }
	describe '#call' do
		context 'when the file does not exist' do
			it 'returns and empty hash' do
				allow(rcf).to receive(:rc_file_exist?).and_return(false)
				expect(rcf).to be_a RCFile
				expect(rcf.call("filename")).to eql({})
			end
		end
		context 'when the rcfile returns nil when read' do
			it 'exits with a loading yaml error' do
				allow(rcf).to receive(:rc_file_exist?).and_return(true)
				allow(rcf).to receive(:read_rc_file).and_return(nil)
				expect(rcf).to receive(:exit_error_loading_yaml)
				rcf.call('filename')
			end
		end

	end
	
end
