#!/usr/bin/env bash

bundle exec honeybadger deploy -e ${RAILS_ENV} -u release-job -s ${GIT_REV} -r git@github.com:hebron-george/happy_youtube_watcher.git
