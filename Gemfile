source 'https://rubygems.org'

ruby '2.4.3'

gem 'api-pagination'
gem 'apipie-rails'
gem 'audited', '~> 4.5'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-ses', '~> 1'
gem 'aws-sdk-rails', '~> 2'
gem 'browser'
gem 'coffee-rails'
gem 'exception_notification'
gem 'gon'
gem 'haml-rails'
gem 'httparty'
gem 'jquery-fileupload-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'nokogiri'
gem 'pg', '~> 0.21.0'
gem 'pg_search'
gem 'rails', '~> 5.1.4'
gem 'rack-pratchett'
gem 'redis', '~> 3.3.5' # until resque updates to support Redis 4
gem 'redis-rails'
gem 'resque'
gem 'resque_mailer'
gem 'resque-scheduler'
gem 'resque-web', require: 'resque_web'
gem 'sanitize'
gem 'sass-rails'
gem 'select2-rails'
gem 'test-unit', '~> 3.0' # required by Heroku for production console
gem 'tinymce-rails', '~> 4.6.7'
gem 'uglifier'
gem 'will_paginate'

group :production do
  gem 'puma'
  gem 'rack-cors'
  gem 'rack-timeout'
  gem 'rails_12factor'
  gem 'tunemygc'
end

group :development do
  gem 'listen'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'web-console', '~> 3.0'
end

group :development, :test do
  gem 'byebug'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'rake', '~> 12.0'
  gem 'seed_dump', '~> 3.2'
  gem 'thin'
  gem 'rspec-rails'
end

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'factory_bot_rails'
  gem 'json'
  gem 'poltergeist'
  gem 'rails-controller-testing'
  gem 'resque_spec'
  gem 'rspec-page-regression'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
