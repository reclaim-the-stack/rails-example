# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

abort "no server for you!"

run Rails.application
Rails.application.load_server
