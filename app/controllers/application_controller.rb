class ApplicationController < ActionController::Base
  if ENV["CLOUDFLARE_WORKER_HOST"].present?
    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true unless response_options.key?(:allow_other_host)
      super(options, response_options)
    end
  end
end
