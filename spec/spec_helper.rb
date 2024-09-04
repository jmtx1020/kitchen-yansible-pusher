# frozen_string_literal: true

require 'kitchen/provisioner/yansible_pusher'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expose_dsl_globally = true

  config.filter_run_excluding winrm: true # use this to test on non windows systems


  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
