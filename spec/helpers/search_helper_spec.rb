require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe '#description_match_count' do
    it 'counts every occurrence of every search word, ignoring case' do
      expect(helper.description_match_count("Out of time\nYou're OUT of TIME", %w[out time])).to eq(4)
    end

    it 'treats regex characters in the search as plain text' do
      expect(helper.description_match_count("a.b axb", ['a.b'])).to eq(1)
    end

    it 'is 0 without a description' do
      expect(helper.description_match_count(nil, ['out'])).to eq(0)
    end
  end
end
