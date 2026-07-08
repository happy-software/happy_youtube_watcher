web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: (bundle exec rails db:migrate) && (sh lib/tasks/honeybadger_deploy_notification.sh)
