require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Billionaire
  class Application < Rails::Application
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true

    config.i18n.default_locale = :ru

    config.assets.initialize_on_precompile = true

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.time_zone = 'Almaty'
    # Но это Омск

    config.i18n.default_locale = :ru
    config.i18n.locale = :ru

    I18n.config.available_locales = :ru

    config.i18n.fallbacks = [:en]
  end
end
