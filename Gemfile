source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version")

gem "rails"

gem "bootsnap", require: false
gem "httpx"
gem "importmap-rails"
gem "opengraph_parser"
gem "ostruct" # to avoid deprecation warning, this gem will be removed in Ruby 3.5.0
gem "pg"
gem "propshaft"
gem "puma"
gem "redis"
gem "sidekiq"
gem "stimulus-rails"
gem "turbo-rails"

group :development do
  gem "web-console"
end

group :development, :test do
  gem "dotenv-rails"
  gem "rspec-rails"
end

group :test do
  gem "webmock"
end
