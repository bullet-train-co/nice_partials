source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.3"

gemspec

gem "minitest"
gem "rake"
gem "irb"

if ENV["RAILS_MAIN"]
  gem "rails", github: "rails/rails", branch: "main"
else
  gem "rails"
end

gem "view_component"
gem "capybara"

gem "debug"

gem "net-pop", github: "ruby/net-pop" # Declare gem explicitly to workaround bug in Ruby 3.3.3. Ref: https://stackoverflow.com/a/78620570
