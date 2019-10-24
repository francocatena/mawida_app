source 'https://rubygems.org'

gem 'rails', '~> 6.0.0'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'responders'
gem 'mini_magick'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'validates_timeliness'
gem 'redcarpet'
gem 'whenever'
gem 'paper_trail'
gem 'carrierwave'
gem 'acts_as_tree'
gem 'net-ldap'
gem 'rubyzip', require: 'zip'
gem 'prawn'
gem 'prawn-table'
gem 'clbustos-rtf', require: 'rtf'
gem 'figaro'
gem 'business_time'
gem 'bootstrap'
gem 'font-awesome-sass'
gem 'will_paginate'
gem 'bootstrap-will_paginate'
gem 'jbuilder'
gem 'sidekiq', '< 6.0'
gem 'ruby-ntlm'
gem 'chartist-rails'
gem 'rails-controller-testing' # TODO: remove after decouple test from assigns

gem 'nakayoshi_fork' # TODO: remove when MRI GC gets fixed, see https://github.com/ko1/nakayoshi_fork

gem 'sassc-rails'
gem 'uglifier'
gem 'sprockets'

gem 'unicorn'

group :development do
  gem 'unicorn-rails'
  gem 'web-console'
  gem 'listen'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'

  gem 'rubocop-github'

  # Support for ed25519 ssh keys
  gem 'ed25519'
  gem 'bcrypt_pbkdf'
end

group :test do
  gem 'sqlite3'
  gem 'timecop'
end

group :development, :test do
  gem 'byebug'
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
