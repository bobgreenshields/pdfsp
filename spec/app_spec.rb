require_relative '../lib/pdfsp'

include Pdfsp

describe App do
	describe '#check_for_pdftk' do
		context 'when present' do
			it 'returns true' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", true])
				app = App.new(cmd: cmd_dbl)
				expect(app.check_for_pdftk).to be_truthy
			end
		end
		context 'when not present' do
			it 'returns false' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				expect(app.check_for_pdftk).to be_falsey
			end
		end
	end

	describe 'process_args' do
		context 'when first arg is a filename' do
			it 'returns a pathname of the file' do
				args = ["/home/bobg/scan.pdf", 3, 5, 6]
				cmd_dbl = double
				app = App.new(cmd: cmd_dbl)
				pdf, _ = app.process_args(args)
				expect(pdf).to be_a Pathname
				expect(pdf.to_s).to eql "/home/bobg/scan.pdf"
			end
			it 'returns an array of the page numbers' do
				args = ["/home/bobg/scan.pdf", 3, 5, 6]
				cmd_dbl = double
				app = App.new(cmd: cmd_dbl)
				_, pages = app.process_args(args)
				expect(pages).to eql [3,5,6]
			end
			it 'sorts the page munbers' do
				args = ["/home/bobg/scan.pdf", 6, 5, 3]
				cmd_dbl = double
				app = App.new(cmd: cmd_dbl)
				_, pages = app.process_args(args)
				expect(pages).to eql [3,5,6]
				
			end
		end
	end

	describe '#get_no_pages' do
		it 'returns the number of pages in the pdf' do
			pdf = "~/scan.pdf"
			cmd_dbl = double
			allow(cmd_dbl).to receive(:call).and_return(["NumberOfPages:  15", true])
			expect(cmd_dbl).to receive(:call).with("pdftk ~/scan.pdf dump_data | grep NumberOfPages")
			app = App.new(cmd: cmd_dbl)
			expect(app.get_no_pages(pdf)).to eql(15)
		end
	end

end


