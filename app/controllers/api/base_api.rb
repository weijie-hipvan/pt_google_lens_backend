# frozen_string_literal: true

require "grape-swagger"

module API
  class BaseAPI < Grape::API
    if Rails.env.development?
      use GrapeLogging::Middleware::RequestLogger, logger: logger, formatter: GrapeLogging::Formatters::Rails.new

      before do
        route_path = env["PATH_INFO"]
        http_method = env["REQUEST_METHOD"]
        action = route&.options&.[](:description) || route&.path
        puts "\e[32m Processing request: [#{http_method}] #{route_path} | Action: #{action} \e[0m"
      end
    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      puts "\e[31m Has error: #{e.message} \e[0m" if Rails.env.development?

      begin
        Rails.logger.info "Exception sent to Sentry: #{e.class.name} - #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Failed to send exception to Sentry: #{e.message}"
      end

      error!({ status: false, message: e.message, code: 400 }, 400)
    end

    rescue_from :all do |e|
      puts "\e[31m Has error: #{e.message} \e[0m" if Rails.env.development?

      # Log backtrace in development
      if Rails.env.development?
        puts "\e[31m Backtrace: \e[0m"
        puts e.backtrace.select { |line| line.include?("/app/") }.each { |line| puts line }
      end

      error!({ status: false, message: e.message, code: 500 }, 500)
    end

    format :json
    content_type :json, "application/json"
    content_type :multipart, "multipart/form-data"
    prefix :api
  end
end
