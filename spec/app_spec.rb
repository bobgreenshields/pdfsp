require_relative '../lib/app'

include Pdfsp

describe App do
	let(:app) do
		result = App.new(settings: settings, options: options) 
		allow(result).to receive(:pdftk_present?).and_return(true)
		result
	end

	describe '#destdir' do
		context 'when options contains cloudfile' do
			let(:options) { {cloudfile: nil} }
			context 'when there is no cloudfile setting' do
				let(:settings) { {} }
				it 'exits with an error' do
					expect(app).to receive(:exit_cloudfile_not_set)
					allow(app).to receive(:cloudfile)
					app.destdir
				end
			end
			context 'when there is a cloudfile setting' do
				let(:settings) { {'cloudfile' => '/test/cloudfile'} }
				it 'returns a pathname' do
					expect(app).not_to receive(:exit_cloudfile_not_set)
					allow(app).to receive(:directory?).and_return(true)
					expect(app.destdir).to be_a Pathname
				end
				it 'returns the cloudfile dir' do
					expect(app).not_to receive(:exit_cloudfile_not_set)
					allow(app).to receive(:directory?).and_return(true)
					expect(app.destdir.to_s).to eql('/test/cloudfile')
				end
				context 'when the cloudfile setting is not a valid dir' do
					it 'exits with an error' do
						expect(app).to receive(:exit_invalid_cloudfile_dir)
						allow(app).to receive(:directory?).and_return(false)
						app.destdir
					end
				end
			end
		end
		context 'when options contains destdir' do
			let(:options) { {destdir: '/test/destdir'} }
			let(:settings) { {} }
			it 'returns the destdir value' do
				expect(app.destdir).to eql('/test/destdir')
			end
		end
		context 'when options does not contain destdir' do
			let(:options) { {} }
			let(:settings) { {} }
			it 'returns the pwd' do
				expect(app.destdir).to eql(Pathname.pwd)
			end
		end
	end

	describe '#pages' do
		let(:options) { {pagelist: pagelist} }
		let(:settings) { {} }
		context 'when pagelist contains duplicates' do
			let(:pagelist) { [3, 5, 7, 7, 14] }
			it 'exits with an error' do
				allow(app).to receive(:no_pages).and_return(14)
				expect(app).to receive(:exit_duplicate_pages)
				app.pages
			end
		end
		context 'when pagelist top number is above the pdf page count' do
			let(:pagelist) { [3, 5, 7, 14] }
			it 'exits with an error' do
				allow(app).to receive(:no_pages).and_return(12)
				expect(app).to receive(:exit_too_many_pages)
				app.pages
			end
		end
		context 'when pagelist top number is the pdf page count' do
			let(:pagelist) { [3, 5, 7, 14] }
			it 'returns the list of pages' do
				allow(app).to receive(:no_pages).and_return(14)
				expect(app.pages).to eql(pagelist)
			end
		end
		context 'when pagelist top number is below the pdf page count' do
			let(:pagelist) { [3, 5, 7, 12] }
			it 'returns the list of pages with the pdf page count appended' do
				allow(app).to receive(:no_pages).and_return(14)
				expected = pagelist + [14]
				expect(app.pages).to eql(expected)
			end
		end
	end

	describe '#page_ranges' do
		let(:options) { {} }
		let(:settings) { {} }
		context 'when pagelist starts with 1' do
			let(:pagelist) { [1, 3, 5, 7, 14] }
			it 'returns an array starting with 1' do
				allow(app).to receive(:pages).and_return(pagelist)
				expect(app.page_ranges[0]).to eql('1')
			end
		end
		context 'when pagelist contains consecutive numbers' do
			let(:pagelist) { [2, 3, 4, 5, 9, 10, 14] }
			it 'returns single pages' do
				allow(app).to receive(:pages).and_return(pagelist)
				expected = %w(1-2 3 4 5 6-9 10 11-14)
				expect(app.page_ranges).to eql(expected)
			end
		end
	end

	describe '#cmd_strings' do
		let(:options) { {} }
		let(:settings) { {} }
		context 'when page_ranges contains single pages' do
			let(:ranges) { %w(1 2 3-4 5) }
			it 'returns cmds with just the single pages' do
				allow(app).to receive(:page_ranges).and_return(ranges)
				allow(app).to receive(:source).and_return(Pathname.new('/test/source.pdf'))
				allow(app).to receive(:destdir).and_return(Pathname.new('/test/destdir'))
				expected = ['pdftk /test/source.pdf cat 1 output /test/destdir/source_1.pdf',
					'pdftk /test/source.pdf cat 2 output /test/destdir/source_2.pdf',
					'pdftk /test/source.pdf cat 3-4 output /test/destdir/source_3-4.pdf',
					'pdftk /test/source.pdf cat 5 output /test/destdir/source_5.pdf']
				expect(app.cmd_strings).to eql(expected)
			end
		end
	end

	describe '#call' do
		context 'when dest is defined in the options' do
			it 'makes the correct calls' do
				cmd = CmdDbl.new
				settings = {}
				options = {source: Pathname.new('/test/source.pdf'),
								destdir: Pathname.new('/test/destdir'),
								pagelist: [1,3,4,8]}
				app = App.new(settings: settings, options: options, cmd: cmd )
				allow(app).to receive(:pdftk_present?).and_return(true)
				allow(app).to receive(:directory?).and_return(true)
				allow(app).to receive(:no_pages).and_return(10)
				allow(app).to receive(:exit_with_0)
				expected = ['pdftk /test/source.pdf cat 1 output /test/destdir/source_1.pdf',
					'pdftk /test/source.pdf cat 2-3 output /test/destdir/source_2-3.pdf',
					'pdftk /test/source.pdf cat 4 output /test/destdir/source_4.pdf',
					'pdftk /test/source.pdf cat 5-8 output /test/destdir/source_5-8.pdf',
					'pdftk /test/source.pdf cat 9-10 output /test/destdir/source_9-10.pdf']
				app.call
				expect(cmd.calls).to eql(expected)
			end
		end
		context 'when dest is defined using cloudfile' do
			it 'makes the correct calls' do
				cmd = CmdDbl.new
				settings = {'cloudfile' => '/test/cloudfile'}
				options = {source: Pathname.new('/test/source.pdf'),
								cloudfile: nil,
								pagelist: [1,3,4,8]}
				app = App.new(settings: settings, options: options, cmd: cmd )
				allow(app).to receive(:pdftk_present?).and_return(true)
				allow(app).to receive(:directory?).and_return(true)
				allow(app).to receive(:no_pages).and_return(10)
				allow(app).to receive(:exit_with_0)
				expected = ['pdftk /test/source.pdf cat 1 output /test/cloudfile/source_1.pdf',
					'pdftk /test/source.pdf cat 2-3 output /test/cloudfile/source_2-3.pdf',
					'pdftk /test/source.pdf cat 4 output /test/cloudfile/source_4.pdf',
					'pdftk /test/source.pdf cat 5-8 output /test/cloudfile/source_5-8.pdf',
					'pdftk /test/source.pdf cat 9-10 output /test/cloudfile/source_9-10.pdf']
				app.call
				expect(cmd.calls).to eql(expected)
			end
		end
		
	end
	
end
