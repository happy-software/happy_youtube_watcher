require 'rails_helper'

RSpec.describe ArchiveWorker do
  describe '.archive_videos' do
    let(:playlist_delta) do
      instance_double(PlaylistDelta,
        id: 1,
        added: [
          { 'url' => 'https://www.youtube.com/watch?v=abc123', 'title' => 'Song A' },
          { 'url' => 'https://www.youtube.com/watch?v=def456', 'title' => 'Song B' },
        ]
      )
    end

    it 'enqueues a job for each added video' do
      expect {
        described_class.archive_videos(playlist_delta)
      }.to change { described_class.jobs.size }.by(2)
    end

    it 'passes the correct urls to the enqueued jobs' do
      described_class.archive_videos(playlist_delta)
      job_urls = described_class.jobs.map { |j| j['args'].first }
      expect(job_urls).to contain_exactly(
        'https://www.youtube.com/watch?v=abc123',
        'https://www.youtube.com/watch?v=def456'
      )
    end

    it 'passes the playlist_delta id to each enqueued job' do
      described_class.archive_videos(playlist_delta)
      job_delta_ids = described_class.jobs.map { |j| j['args'].last }
      expect(job_delta_ids).to all(eq(1))
    end

    context 'when there are no added videos' do
      let(:playlist_delta) { instance_double(PlaylistDelta, id: 1, added: []) }

      it 'enqueues no jobs' do
        expect {
          described_class.archive_videos(playlist_delta)
        }.not_to change { described_class.jobs.size }
      end
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }
    let(:url) { 'https://www.youtube.com/watch?v=abc123' }
    let(:encoded_url) { URI.encode_www_form_component(url) }
    let(:playlist_delta_id) { 1 }

    before do
      stub_request(:get, "https://web.archive.org/save/#{encoded_url}").to_return(status: 200)
    end

    it 'makes a GET request to the web archive API with the encoded URL' do
      worker.perform(url, playlist_delta_id)
      expect(WebMock).to have_requested(:get, "https://web.archive.org/save/#{encoded_url}")
    end

    it 'handles Net::OpenTimeout gracefully without raising' do
      stub_request(:get, /web\.archive\.org/).to_raise(Net::OpenTimeout)
      expect { worker.perform(url, playlist_delta_id) }.not_to raise_error
    end

    it 'handles Net::ReadTimeout gracefully without raising' do
      stub_request(:get, /web\.archive\.org/).to_raise(Net::ReadTimeout)
      expect { worker.perform(url, playlist_delta_id) }.not_to raise_error
    end
  end
end
