require 'spec_helper'
require 'kitchen/driver/docker'
require 'kitchen/provisioner/yansible_pusher'
require 'kitchen/verifier/busser'
require 'kitchen/loader/yaml'
require 'kitchen/config'
require 'fileutils'

describe 'YansiblePusher Windows Integration(WinRM)', :winrm do
  before(:all) do
    Kitchen.logger = Kitchen.default_file_logger
  end

  let(:loader) do
    Kitchen::Loader::YAML.new(
      project_config: File.expand_path('../../test/integration/ansible/kitchen_win.yml', __dir__)
    )
  end

  let(:config) { Kitchen::Config.new(loader: loader) }
  let(:instance) { config.instances.first }
  let(:kitchen_root) { File.expand_path('../..', __dir__) }
  let(:log_file) { File.join(kitchen_root, '.kitchen', 'logs', "#{instance.name}.log") }

  before(:each) do
    instance.create
  end

  after(:each) do
    instance.destroy
  rescue => e
    puts "Error during instance destruction: #{e.message}"
  ensure
    FileUtils.rm_rf(instance.instance_variable_get(:@data_path)) if instance.instance_variable_get(:@data_path)
  end

  it 'verifies ansible playbook execution on windows via WinRM' do
    # Ensure the log directory exists
    FileUtils.mkdir_p(File.dirname(log_file))

    # Clear the log file before running converge
    File.write(log_file, '')

    # Run the converge action
    instance.converge
    # expect { instance.test }.not_to raise_error

    # Read the log file
    log_content = File.read(log_file)

    # Perform checks on the log content
    expect(log_content).to include('Running Ansible Playbook')
    expect(log_content).to include('Ansible Playbook Complete!')
  end
end