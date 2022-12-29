source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

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
