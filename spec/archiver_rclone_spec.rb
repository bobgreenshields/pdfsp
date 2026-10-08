require_relative '../lib/archiver'

include Pdfsp

describe Archiver::ArchiverRclone do
	let(:settings) { {'type' => 'rclone', 'remote' => 's3scans:my-bucket'} }
	let(:cmd) { double('cmd') }
	let(:archiver) { Archiver::ArchiverRclone.new(settings, cmd: cmd) }
	let(:source) { Pathname.new('/home/bob/My Scan (1).pdf') }
	let(:dest) { 's3scans:my-bucket/My_Scan_(1).pdf' }

	before { allow(STDERR).to receive(:puts) }

	describe '::suitable?' do
		it 'is true for an rclone type with a remote' do
			expect(Archiver::ArchiverRclone.suitable?(settings)).to be true
		end
		it 'is false without a remote' do
			expect(Archiver::ArchiverRclone.suitable?({'type' => 'rclone'})).to be false
		end
		it 'is false for a blank remote' do
			expect(Archiver::ArchiverRclone.suitable?({'type' => 'rclone', 'remote' => ' '})).to be false
		end
		it 'is false for another type' do
			expect(Archiver::ArchiverRclone.suitable?(settings.merge('type' => 's3'))).to be false
		end
		it 'is false when not a hash' do
			expect(Archiver::ArchiverRclone.suitable?(nil)).to be false
		end
	end

	describe '#destination' do
		it 'replaces spaces with underscores like the original archiver' do
			expect(archiver.target(source)).to eql('My_Scan_(1).pdf')
		end
		it 'joins remote path and filename with a slash' do
			expect(archiver.destination(source)).to eql(dest)
		end
		it 'ignores a trailing slash on the remote' do
			a = Archiver::ArchiverRclone.new(settings.merge('remote' => 's3scans:my-bucket/'), cmd: cmd)
			expect(a.destination(source)).to eql(dest)
		end
		it 'does not add a slash after a bare remote name' do
			a = Archiver::ArchiverRclone.new(settings.merge('remote' => 's3scans:'), cmd: cmd)
			expect(a.destination(source)).to eql('s3scans:My_Scan_(1).pdf')
		end
	end

	describe '#call' do
		context 'when the file is not yet archived' do
			before do
				allow(cmd).to receive(:call).with('rclone', 'lsf', '--files-only', dest).and_return(['', false])
			end
			it 'moves it with rclone moveto, passing args separately' do
				expect(cmd).to receive(:call).with('rclone', 'moveto', source.to_s, dest).and_return(['', true])
				expect(archiver.call(source)).to be true
			end
			it 'returns false when rclone fails' do
				allow(cmd).to receive(:call).with('rclone', 'moveto', source.to_s, dest).and_return(['boom', false])
				expect(archiver.call(source)).to be false
			end
		end

		context 'when the file is already archived' do
			it 'does not upload again but deletes the local file' do
				allow(cmd).to receive(:call).with('rclone', 'lsf', '--files-only', dest).and_return(["My_Scan_(1).pdf\n", true])
				expect(cmd).not_to receive(:call).with('rclone', 'moveto', any_args)
				expect(source).to receive(:delete)
				expect(archiver.call(source)).to be true
			end
		end

		context 'when rclone lists something that is not the file' do
			it 'treats it as not archived' do
				allow(cmd).to receive(:call).with('rclone', 'lsf', '--files-only', dest).and_return(["other.pdf\n", true])
				expect(cmd).to receive(:call).with('rclone', 'moveto', source.to_s, dest).and_return(['', true])
				expect(archiver.call(source)).to be true
			end
		end

		context 'when S3 returns exit 0 with no output for a missing file' do
			it 'treats it as not archived' do
				allow(cmd).to receive(:call).with('rclone', 'lsf', '--files-only', dest).and_return(['', true])
				expect(cmd).to receive(:call).with('rclone', 'moveto', source.to_s, dest).and_return(['', true])
				expect(archiver.call(source)).to be true
			end
		end

		context 'when rclone is not installed' do
			it 'reports it and returns false' do
				allow(cmd).to receive(:call).and_raise(Errno::ENOENT)
				expect(archiver.call(source)).to be false
			end
		end

		it 'uses a custom rclone binary when set' do
			a = Archiver::ArchiverRclone.new(settings.merge('rclone' => '/opt/rclone'), cmd: cmd)
			expect(cmd).to receive(:call).with('/opt/rclone', 'lsf', '--files-only', dest).and_return(['', false])
			expect(cmd).to receive(:call).with('/opt/rclone', 'moveto', source.to_s, dest).and_return(['', true])
			a.call(source)
		end
	end

	describe 'Archiver.instance' do
		it 'returns an ArchiverRclone for rclone settings' do
			expect(Archiver.instance({'archiver' => settings})).to be_a(Archiver::ArchiverRclone)
		end
	end
end
