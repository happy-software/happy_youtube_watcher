RSpec.configure do |config|
  config.before(:each) do
    allow(YoutubeWatcher::Slacker).to receive(:post_message)
  end
end
