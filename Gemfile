source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version")

gem "rails", github: "rails/rails", branch: "main"

gem "bootsnap", require: false
gem "importmap-rails"
gem "pg"
gem "propshaft"
gem "puma"
gem "redis"
gem "stimulus-rails"
gem "turbo-rails"

group :development do
  gem "web-console"
end
