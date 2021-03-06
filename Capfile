load 'deploy' if respond_to?(:namespace)
require "bundler/capistrano"

set :application, "image-proxy"
set :user, "ubuntu"
set :use_sudo, false

set :scm, :git
set :repository,  "git@github.com:cvincent/image-proxy.git"
set :deploy_via, :remote_cache
set :deploy_to, "/#{application}"

servers = (1..1).map { |i| "sweetstakes-i#{i}" }

role :app, *servers
role :web, *servers
role :db,  *servers.first, primary: true

set :runner, user
set :admin_runner, user

namespace :deploy do
  task :start, roles: [:web, :app] do
    run "cd #{deploy_to}/current && nohup bundle exec thin -C thin.yml -R config.ru start"
  end

  task :stop, roles: [:web, :app] do
    run "cd #{deploy_to}/current && nohup bundle exec thin -C thin.yml -R config.ru stop"
  end

  task :restart, roles: [:web, :app] do
    deploy.stop
    deploy.start
  end

  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end

namespace :"image-proxy" do
  task :log do
    run "cat #{deploy_to}/current/log/thin.log"
  end
end
