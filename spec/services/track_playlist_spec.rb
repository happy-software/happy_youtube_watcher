require 'rails_helper'

RSpec.describe TrackPlaylist do
  describe '.get_playlist_id_from_raw' do
    subject { described_class.get_playlist_id_from_raw(raw) }

    let(:playlist_id) { 'PLcFOqboUiUccAbCdEf_-123' }

    context 'with a bare playlist id' do
      let(:raw) { playlist_id }

      it { is_expected.to eq(playlist_id) }
    end

    context 'with a playlist URL copied from the browser' do
      let(:raw) { "https://www.youtube.com/playlist?list=#{playlist_id}" }

      it { is_expected.to eq(playlist_id) }
    end

    context 'with a video URL that is playing from the playlist' do
      let(:raw) { "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=#{playlist_id}&index=3" }

      it { is_expected.to eq(playlist_id) }
    end

    context 'with a mobile playlist URL' do
      let(:raw) { "https://m.youtube.com/playlist?list=#{playlist_id}" }

      it { is_expected.to eq(playlist_id) }
    end

    context 'with a URL that has no list parameter' do
      let(:raw) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

      it 'raises InvalidPlaylistId' do
        expect { subject }.to raise_error(TrackedPlaylist::InvalidPlaylistId)
      end
    end

    context 'with a URL that has no query string at all' do
      let(:raw) { 'https://www.youtube.com/feed/playlists' }

      it 'raises InvalidPlaylistId' do
        expect { subject }.to raise_error(TrackedPlaylist::InvalidPlaylistId)
      end
    end

    context 'with a playlist id that is too short' do
      let(:raw) { 'https://www.youtube.com/playlist?list=PLshort' }

      it 'raises InvalidPlaylistId' do
        expect { subject }.to raise_error(TrackedPlaylist::InvalidPlaylistId)
      end
    end
  end
end
