require "bundler/setup"

Bundler.require :test

require "watchable_properties"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
