require 'playlist_difference_renderer'

RSpec.describe PlaylistDifferenceRenderer do
  let(:playlist_id)   { 'some-playlist-id' }
  let(:playlist_name) { 'some-playlist-name' }
  let(:diffs)         { double('diff object', removed_songs: removed_songs, added_songs: added_songs) }
  let(:removed_songs) { [double('song1', position: 1, title: 'removed song1', url: 'asdf')] }
  let(:added_songs)   { [double('song1', position: 1, title: 'added song1', url: 'jkl;')] }

  describe '.post_diff' do
    subject { described_class.post_diff(diffs, playlist_id, playlist_name) }

    before do
      allow(described_class).to receive(:create_diff_message).and_return("a message")
      allow(::YoutubeWatcher::Slacker).to receive(:post_message)
    end

    it 'will create a diff message and send it' do
      expect(::YoutubeWatcher::Slacker).to receive(:post_message).with("a message", "#happy-hood")
      subject
    end
  end

  describe '.create_diff_message' do
    subject { described_class.create_diff_message(diffs, playlist_id, playlist_name) }

    let(:expected_message) do
      "some-playlist-name - (https://youtube.com/playlist?list=some-playlist-id) - #{Date.today.readable_inspect}\n\n\n"\
      "These songs were removed:\n "\
      "```Position: 1 - removed song1 - ID(asdf)```\n"\
      "You can search for removed songs here:\n "\
      "```'removed song1': https://www.youtube.com/results?search_query=removed+song1```\n"\
      "These songs were added:\n```Position: 1 - added"\
      " song1 - ID(jkl;)```"
    end

    it 'builds a message of added and removed songs' do
      expect(subject).to eq(expected_message)
    end
  end
end
