require 'openteam/capistrano/deploy'

set :bundle_binstubs, -> { shared_path.join('bin') }

set :db_remote_clean, true

set :slackistrano,
  channel: (Settings['slack.channel'] rescue ''),
  webhook: (Settings['slack.webhook'] rescue '')
