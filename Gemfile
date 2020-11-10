source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.2'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem "puma", ">= 4.3.5"
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.1', '>= 5.1.0'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.2', '>= 4.2.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.2', '>= 5.2.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.4', '>= 1.4.5'

gem 'devise', '~> 4.7', '>= 4.7.1'
gem 'font-awesome-rails', '>= 4.7.0.5'
gem 'font_assets', '>= 0.1.14'
gem 'bootstrap', '~> 4.4', '>= 4.4.1'

gem 'money-rails', '~> 1.13', '>= 1.13.3'

gem 'verbalize', '~> 2.2'

gem 'kaminari'

gem 'cocoon'

# Add versions table for logging purposes
gem 'paper_trail', '>= 10.3.1'

gem 'sentry-raven'
gem 'sidekiq', '>= 6.0.5'
gem 'skylight', '>= 4.2.1'

gem 'brakeman'
gem 'bundler-audit'

group :production do
  gem 'sqreen', '>= 1.16'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'table_print'
  # For better error pages with Pry console
  gem 'better_errors'
  gem 'binding_of_caller'

  # RSpec & testing gems!
  gem 'rspec-rails', '~> 4.0.0.0'
  gem 'rspec', github: 'rspec/rspec', branch: 'master'
  gem 'rspec-core', github: 'rspec/rspec-core', branch: 'master'
  gem 'rspec-mocks', github: 'rspec/rspec-mocks', branch: 'master'
  gem 'rspec-expectations', github: 'rspec/rspec-expectations', branch: 'master'
  gem 'rspec-support', github: 'rspec/rspec-support', branch: 'master'
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'shoulda-matchers', '~> 4.1', '>= 4.1.2'
  # Test data generation
  gem 'factory_bot_rails', '~> 5.1', '>= 5.1.1'
  gem 'faker', :git => 'https://github.com/stympy/faker.git', :branch => 'master'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.0.1'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.29.0'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'webdrivers', '~> 4.1', '>= 4.1.3'

  # This is used in CI
  gem 'rspec_junit_formatter', '~> 0.4.1'
  gem 'rspec-benchmark'
  gem 'timecop', '0.9.1'
  gem 'database_cleaner-active_record', '>= 1.8.0'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
