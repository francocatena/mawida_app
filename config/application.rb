require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require *Rails.groups

module MawidaBP
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake time:zones:all" for a time zone names list. Default is UTC.
    config.time_zone = ENV['TRAVIS'] ? 'UTC' : 'Buenos Aires'

    # Be sure to have the adapter's gem in your Gemfile
    # and follow the adapter's specific installation
    # and deployment instructions.
    config.active_job.queue_adapter = :sidekiq

    # Disable IP spoofing check
    config.action_dispatch.ip_spoofing_check = false
  end
end
