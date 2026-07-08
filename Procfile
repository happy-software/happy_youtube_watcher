web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate && (bundle exec honeybadger deploy -e ${RAILS_ENV} -u release-job -s ${GIT_REV} -r git@github.com:hebron-george/happy_youtube_watcher.git || true)
