require 'rails_helper'

RSpec.describe DailySnapshotWorker do
  describe '#perform' do
    it 'calls PlaylistSnapshot.capture_all_tracked_playlists!' do
      expect(PlaylistSnapshot).to receive(:capture_all_tracked_playlists!)
      described_class.new.perform
    end
  end

  it "doesn't retry, since a retry spends the YouTube quota again" do
    expect(described_class.get_sidekiq_options['retry']).to be false
  end
end
