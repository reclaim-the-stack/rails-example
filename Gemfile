source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version")

gem "rails", github: "rails/rails", branch: "main"

gem "bootsnap", require: false
gem "httpx"
gem "importmap-rails"
gem "opengraph_parser"
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
