require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EventallyRuby
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.i18n.available_locales = [:ru, :en]
    config.i18n.default_locale = :ru

    config.x.mailer_from = ENV["MAILER_FROM"].presence || ENV["SMTP_USERNAME"].presence || "no-reply@eventally.local"
    config.action_mailer.default_options = { from: %("Eventally" <#{config.x.mailer_from}>) }

    if ENV["SMTP_USERNAME"].present?
      smtp_port = ENV.fetch("SMTP_PORT", "465").to_i
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.perform_deliveries = true
      config.action_mailer.smtp_settings = {
        address: ENV.fetch("SMTP_ADDRESS", "smtp.yandex.ru"),
        port: smtp_port,
        domain: ENV.fetch("SMTP_DOMAIN", "localhost"),
        user_name: ENV["SMTP_USERNAME"],
        password: ENV["SMTP_PASSWORD"],
        authentication: :plain,
        ssl: smtp_port == 465,
        enable_starttls_auto: smtp_port != 465,
        open_timeout: 10,
        read_timeout: 10
      }
    end
  end
end
