# frozen_string_literal: true

require 'kitchen/provisioner/yansible_pusher'

# Load all integration test files
Dir[File.expand_path("../integration/**/*_spec.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expose_dsl_globally = true


  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
