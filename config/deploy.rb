require 'openteam/capistrano/deploy'

# append :linked_dirs, 'data'

set :slackistrano,
  channel: (Settings['slack.channel'] rescue ''),
  webhook: (Settings['slack.webhook'] rescue '')
