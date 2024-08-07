source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.open('.ruby-version', 'rb') { |f| f.read.chomp }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 5.6.8'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.10'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 4.0.0'
  gem 'rspec'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'dotenv-rails', groups: [:development, :test]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'yt', '~> 0.33'
gem 'pry-rails'

gem 'rack-cors'
gem 'slack-ruby-client'

gem 'chartkick'
gem 'groupdate'

gem 'sentry-raven'
gem 'sentry-ruby'
gem 'sentry-rails'

# Ruby 3.1+ needs the net-smtp gem explicitly required
# https://stackoverflow.com/questions/70500220/rails-7-ruby-3-1-loaderror-cannot-load-such-file-net-smtp/70500221#70500221
gem 'net-smtp', require: false
gem 'net-imap', require: false
gem 'net-pop', require: false
gem "dockerfile-rails", ">= 1.6", :group => :development
