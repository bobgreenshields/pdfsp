require_relative '../lib/pdfsp'

include Pdfsp

describe App do
	describe '#pdftk_present?' do
		context 'when present' do
			it 'returns true' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", true])
				app = App.new(cmd: cmd_dbl)
				expect(app.pdftk_present?).to be_truthy
			end
		end
		context 'when not present' do
			it 'returns false' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				expect(app.pdftk_present?).to be_falsey
			end
		end
	end

	describe '#pages are integers?' do
		context 'when integers (including whitespace) are passed' do
			it 'returns true' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				args = ["/home/bobg/scans.pdf", "3", "  6 ", " 8", "4 ", "10"]
				expect(app.pages_are_integers?(args)).to be_truthy
			end
		end
		context 'when non-integers (including whitespace) are passed' do
			it 'returns false' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				args = ["/home/bobg/scans.pdf", "3", "  6 ", " 3h", "4 ", "10"]
				expect(app.pages_are_integers?(args)).to be_falsey
			end
		end
	end

	describe '#get_pages' do
		it 'returns an array of integers' do
			cmd_dbl = double
			allow(cmd_dbl).to receive(:call).and_return(["", false])
			app = App.new(cmd: cmd_dbl)
			args = ["8", "  6 ", " 3", "4 ", "10"]
			pages = app.get_pages(args)
			expect(pages).to be_a Array
			pages.each do | page |
				expect(page).to be_a Integer
			end
		end
		it 'returns a sorted array' do
			cmd_dbl = double
			allow(cmd_dbl).to receive(:call).and_return(["", false])
			app = App.new(cmd: cmd_dbl)
			args = ["8", "  6 ", " 3", "4 ", "10"]
			expect(app.get_pages(args)).to eql [3,4,6,8,10]
		end
	end

	describe '#has_duplicates?' do
		context 'when no dups exist' do
			it 'returns false' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				page_arr = [1, 3, 4, 8, 22]
				expect(app.has_duplicates?(page_arr)).to be_falsey
			end
		end
		context 'when dups exist' do
			it 'returns true' do
				cmd_dbl = double
				allow(cmd_dbl).to receive(:call).and_return(["", false])
				app = App.new(cmd: cmd_dbl)
				page_arr = [1, 3, 4, 4, 8, 22]
				expect(app.has_duplicates?(page_arr)).to be_truthy
			end
		end
	end

	describe '#ranges' do
		it 'outputs individual pages without a hyphen' do
			cmd_dbl = double
			app = App.new(cmd: cmd_dbl)
			expect(app.ranges([1,2,3,5])[0]).to eql "1"
			expect(app.ranges([1,2,3,5])[1]).to eql "2"
			expect(app.ranges([1,2,3,5])[2]).to eql "3"
		end
		it 'outputs ranges with a hyphen' do
			cmd_dbl = double
			app = App.new(cmd: cmd_dbl)
			expect(app.ranges([1,2,3,5])[3]).to eql "4-5"
		end
		it 'outputs the correct number of ranges' do
			cmd_dbl = double
			app = App.new(cmd: cmd_dbl)
			expect(app.ranges([1,2,5,6,8,12,13]).length).to eql 7
		end
		it 'outputs the correct ranges' do
			cmd_dbl = double
			app = App.new(cmd: cmd_dbl)
			ranges = app.ranges([1,2,5,6,8,12,13])
			expected = %w(1 2 3-5 6 7-8 9-12 13)
			ranges.each_with_index do | range, index |
				expect(range).to eql expected[index]
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


