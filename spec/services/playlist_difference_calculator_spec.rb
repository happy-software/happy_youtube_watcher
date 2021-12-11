require 'playlist_difference_calculator'

RSpec.describe PlaylistDifferenceCalculator do
  describe '.calculate_diffs' do
    subject { described_class.calculate_diffs({}, {}) }

    it { is_expected.to be_a(PlaylistDifferenceCalculator) }
  end

  describe 'PlaylistDifferenceCalculator object' do
    let(:instance) { PlaylistDifferenceCalculator.new(diffs) }
    let(:diffs)    { {added: added, removed: removed} }
    let(:added)    { [] }
    let(:removed)  { [] }

    describe '#any_changes?' do
      subject { instance.any_changes? }

      context 'with no changes' do
        it { is_expected.to eq(false) }
      end

      context 'with changes' do
        let(:added) { [{some: :song}] }
        it { is_expected.to eq(true) }
      end
    end

    describe '#removed_songs' do
      subject { instance.removed_songs }

      context 'with no songs removed' do
        it { is_expected.to eq([]) }
      end

      context 'with removed songs' do
        let(:removed) do
          [{position: 618, title: 'Removed Song 1', resourceId: {videoId: 'videoId1'}}]
        end

        it 'has the removed songs available' do
          expect(subject.count).to eq(1)
          expect(subject.first.position).to eq(618)
          expect(subject.first.title).to eq('Removed Song 1')
          expect(subject.first.url).to eq('https://youtube.com/watch?v=videoId1')
        end
      end
    end

    describe '#added_songs' do
      subject { instance.added_songs }

      context 'with no added songs' do
        it { is_expected.to eq([]) }
      end

      context 'with added songs' do
        let(:added) do
          [{position: 618, title: 'Added Song 1', resourceId: {videoId: 'videoId2'}}]
        end

        it 'has the removed songs available' do
          expect(subject.count).to eq(1)
          expect(subject.first.position).to eq(618)
          expect(subject.first.title).to eq('Added Song 1')
          expect(subject.first.url).to eq('https://youtube.com/watch?v=videoId2')
        end
      end
    end
  end
end
