source 'https://rubygems.org'

gem 'rails', '~> 4.2.3'

gem 'arel', '6.0.0' # Temporal 6.0.2 fix

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'mini_magick'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'validates_timeliness', github: 'francocatena/validates_timeliness'
gem 'RedCloth'
gem 'whenever'
gem 'paper_trail'
gem 'carrierwave'
gem 'dynamic_form'
gem 'acts_as_tree'
gem 'net-ldap'
gem 'rubyzip', require: 'zip'
gem 'prawn'
gem 'prawn-table'
gem 'figaro'
gem 'bloggy', require: false
gem 'irreverent'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'search_cop'
gem 'jbuilder'
gem 'sidekiq'

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'sprockets'

gem 'unicorn'

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-sidekiq'
  gem 'unicorn-rails'
end

group :test do
  gem 'sqlite3'
  gem 'timecop'
end

group :development, :test do
  gem 'spring'
  gem 'byebug'
  gem 'web-console'
end

# Include database gems for the adapters found in the database configuration file
require 'erb'
require 'yaml'

database_file = File.join File.dirname(__FILE__), 'config/database.yml'

if File.exist? database_file
  database_config = YAML::load ERB.new(IO.read(database_file)).result
  adapters        = database_config.values.map { |c| c['adapter'] }.compact.uniq

  adapters.each do |adapter|
    case adapter
    when /postgresql/
      gem 'pg'
    when /oracle/
      group :development, :production do
        gem 'ruby-oci8'
        gem 'activerecord-oracle_enhanced-adapter'
      end
    end
  end
end
