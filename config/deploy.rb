set :application, 'mawidabp.com'
set :user, 'deployer'
set :repo_url, 'https://github.com/cirope/mawidabp.git'

set :format, :pretty
set :log_level, :info

set :deploy_to, "/var/www/#{fetch(:application)}"
set :deploy_via, :remote_cache

set :linked_files, %w{config/application.yml config/database.yml}
set :linked_dirs,  %w{log private tmp/pids}

set :rbenv_type, :user
set :rbenv_ruby, '2.5.0'

set :keep_releases, 5

namespace :deploy do
  before :check,      'config:upload'
  before :check,      'config:upload_database_config'
  before :publishing, :db_updates
  after  :publishing, :restart
  after  :finishing,  :help
  after  :finishing,  :cleanup
  after  :published,  'sidekiq:restart'
end
