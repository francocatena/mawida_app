set :branch,    'c-naranja'
set :stage,     :production
set :rails_env, 'production'

set :default_env, {
  'LANG':     'en_US.UTF-8',
  'LANGUAGE': 'en_US.UTF-8',
  'LC_ALL':   'en_US.UTF-8'
}

role :web, %w{deployer@naranja.mawidabp.com}
role :app, %w{deployer@naranja.mawidabp.com}
role :db,  %w{deployer@naranja.mawidabp.com}

server 'naranja.mawidabp.com', user: 'deployer', roles: %w{web app db}
