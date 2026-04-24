require 'rails_helper'

RSpec.describe DeactivateAbandonedPlaylistsWorker do
  describe '#perform' do
    let!(:user) { create(:user) }
    let!(:favorited_playlist) { create(:tracked_playlist) }
    let!(:unfavorited_playlist) { create(:tracked_playlist) }
    let!(:already_inactive_playlist) { create(:tracked_playlist, active: false) }

    before do
      create(:favorite_playlist, user: user, tracked_playlist: favorited_playlist)
    end

    it 'deactivates active playlists that have no favorites' do
      expect {
        described_class.new.perform
      }.to change { unfavorited_playlist.reload.active }.from(true).to(false)
    end

    it 'leaves active playlists that have favorites untouched' do
      described_class.new.perform
      expect(favorited_playlist.reload.active).to be true
    end

    it 'leaves already-inactive playlists untouched' do
      described_class.new.perform
      expect(already_inactive_playlist.reload.active).to be false
    end

    context 'when all active playlists have favorites' do
      before { create(:favorite_playlist, user: user, tracked_playlist: unfavorited_playlist) }

      it 'does not deactivate any playlists' do
        described_class.new.perform
        expect(TrackedPlaylist.where(active: true).count).to eq(2)
      end
    end
  end
end
