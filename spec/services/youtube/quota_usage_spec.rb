require 'rails_helper'

RSpec.describe Youtube::QuotaUsage do
  it 'adds up the units recorded inside the block per endpoint' do
    usage = described_class.track do
      described_class.record('playlistItems')
      described_class.record('playlistItems', 4)
      described_class.record('videos', 2)
    end

    expect(usage.units).to eq('playlistItems' => 5, 'videos' => 2)
    expect(usage.total).to eq(7)
    expect(usage.to_s).to eq('7 units (playlistItems: 5, videos: 2)')
  end

  it 'ignores units recorded outside a block' do
    expect { described_class.record('videos') }.not_to raise_error
    expect(described_class.track { }.total).to eq(0)
  end

  it 'stops tracking once the block raises' do
    expect { described_class.track { raise 'boom' } }.to raise_error('boom')
    expect(Thread.current[described_class::THREAD_KEY]).to be_nil
  end
end
