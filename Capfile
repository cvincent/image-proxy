load 'deploy' if respond_to?(:namespace)
require "bundler/capistrano"

set :application, "image-proxy"
set :user, "ubuntu"
set :use_sudo, false

set :scm, :git
set :repository,  "git@github.com:cvincent/image-proxy.git"
set :deploy_via, :remote_cache
set :deploy_to, "/#{application}"

role :app, "sweetstakes-i1"
role :web, "sweetstakes-i1"
role :db,  "sweetstakes-i1", primary: true

set :runner, user
set :admin_runner, user

namespace :deploy do
  task :start, roles: [:web, :app] do
    run "cd #{deploy_to}/current && nohup thin -C thin.yml -R config.ru start"
  end

  task :stop, roles: [:web, :app] do
    run "cd #{deploy_to}/current && nohup thin -C thin.yml -R config.ru stop"
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
