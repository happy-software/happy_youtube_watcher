require 'rails_helper'

RSpec.describe Youtube::VideoAvailabilityChecker do
  let(:available_status) { { 'privacyStatus' => 'public', 'uploadStatus' => 'processed' } }

  def yt_video(id, status: available_status, content_details: {})
    Yt::Models::Video.new(id: id, status: status, content_details: content_details)
  end

  describe '.annotate' do
    subject { described_class.annotate(playlist_items) }

    let(:playlist_items) do
      {
        'working'   => { 'title' => 'Working Song' },
        'private'   => { 'title' => 'Some Song' },
        'rejected'  => { 'title' => 'Claimed Song' },
        'blocked'   => { 'title' => 'Jailhouse Rock' },
        'gone'      => { 'title' => 'Deleted video' },
        'gone_priv' => { 'title' => 'Private video' },
      }
    end

    let(:videos) do
      [
        yt_video('working'),
        yt_video('private', status: available_status.merge('privacyStatus' => 'private')),
        yt_video('rejected', status: available_status.merge('uploadStatus' => 'rejected')),
        yt_video('blocked', content_details: { 'regionRestriction' => { 'blocked' => Youtube::CountryCodes::ALL } }),
      ]
    end

    before do
      allow(Yt::Collections::Videos).to receive(:new).and_return(double(where: videos))
    end

    it 'marks each video with the reason it is unavailable' do
      reasons = subject.transform_values { |song| song['unavailable_reason'] }
      expect(reasons).to eq(
        'working'   => nil,
        'private'   => 'private',
        'rejected'  => 'deleted',
        'blocked'   => 'region_blocked',
        'gone'      => 'deleted',
        'gone_priv' => 'private',
      )
    end

    it 'keeps the rest of the song data' do
      expect(subject['blocked']['title']).to eq('Jailhouse Rock')
    end

    it 'clears a stale reason once the video is available again' do
      playlist_items['working']['unavailable_reason'] = 'region_blocked'
      expect(subject['working']).not_to have_key('unavailable_reason')
    end

    it 'does not modify the hash passed in' do
      subject
      expect(playlist_items['private']).not_to have_key('unavailable_reason')
    end

    it 'looks up videos in batches of 50' do
      collection = double(where: [])
      allow(Yt::Collections::Videos).to receive(:new).and_return(collection)
      items = (1..120).to_h { |i| ["video#{i}", { 'title' => "Song #{i}" }] }

      described_class.annotate(items)

      expect(collection).to have_received(:where).exactly(3).times
    end

    it 'records 1 unit of quota per batch' do
      allow(Yt::Collections::Videos).to receive(:new).and_return(double(where: []))
      items = (1..120).to_h { |i| ["video#{i}", { 'title' => "Song #{i}" }] }

      usage = Youtube::QuotaUsage.track { described_class.annotate(items) }

      expect(usage.units).to eq('videos' => 3)
    end

    it 'makes no API calls for an empty playlist' do
      expect(Yt::Collections::Videos).not_to receive(:new)
      expect(described_class.annotate({})).to eq({})
    end
  end

  describe '.blocked_everywhere?' do
    it 'is false without a region restriction' do
      expect(described_class.blocked_everywhere?(nil)).to be false
    end

    it 'is true when the allowed list is empty' do
      expect(described_class.blocked_everywhere?('allowed' => [])).to be true
    end

    it 'is false when some countries are allowed' do
      expect(described_class.blocked_everywhere?('allowed' => ['US'])).to be false
    end

    it 'is true when every country is blocked' do
      expect(described_class.blocked_everywhere?('blocked' => Youtube::CountryCodes::ALL)).to be true
    end

    it 'is false when only some countries are blocked' do
      expect(described_class.blocked_everywhere?('blocked' => Youtube::CountryCodes::ALL - ['US'])).to be false
    end

    it 'is false when the blocked list is empty' do
      expect(described_class.blocked_everywhere?('blocked' => [])).to be false
    end
  end
end
