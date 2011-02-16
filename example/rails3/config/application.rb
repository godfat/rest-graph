
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'action_controller/railtie'
require 'rails/test_unit/railtie'

Bundler.require(:default, Rails.env)

module Rails3
  class Application < Rails::Application
    config.encoding = 'utf-8'

    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    config.logger = logger

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
