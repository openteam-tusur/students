require "bundler/capistrano"
require "rvm/capistrano"

load "config/deploy/settings"

namespace :deploy do
  desc "Copy config files"
  task :config_app, :roles => :app do
    run "ln -s #{deploy_to}/shared/config/settings.yml #{release_path}/config/settings.yml"
  end

  desc "HASK copy right unicorn.rb file"
  task :copy_unicorn_config do
    run "ln -s #{deploy_to}/shared/config/unicorn.rb #{deploy_to}/current/config/unicorn.rb"
    run "ln -s #{deploy_to}/shared/config/directories.rb #{deploy_to}/current/config/directories.rb"
  end

  desc "Reload Unicorn"
  task :reload_servers do
    sudo "/etc/init.d/#{unicorn_instance_name} restart"
  end
end

# deploy
after "deploy:finalize_update", "deploy:config_app"
after "deploy", "deploy:copy_unicorn_config"
#after "deploy", "deploy:reload_servers"
after "deploy:restart", "deploy:cleanup"
#after "deploy", "deploy:airbrake"

# deploy:rollback
after "deploy:rollback", "deploy:reload_servers"
