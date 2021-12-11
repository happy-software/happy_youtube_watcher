Yt.configure do |config|
  config.log_level = :debug unless Rails.env.production?
end
