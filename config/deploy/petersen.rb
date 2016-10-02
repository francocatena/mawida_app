set :stage, :production
set :rails_env, 'production'
set :branch, 'oracle'
set :pty, true

role :web, %w{deployer@application.mawidabp.petersen.corp}
role :app, %w{deployer@application.mawidabp.petersen.corp}
role :db,  %w{deployer@application.mawidabp.petersen.corp}

server 'application.mawidabp.petersen.corp', user: 'deployer', roles: %w{web app db}
