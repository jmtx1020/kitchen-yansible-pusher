require 'spec_helper'
require 'kitchen/driver/docker'
require 'kitchen/provisioner/yansible_pusher'
require 'kitchen/verifier/busser'
require 'kitchen/loader/yaml'
require 'kitchen/config'
require 'fileutils'

describe 'YansiblePusher Integration' do
  let(:loader) do
    Kitchen::Loader::YAML.new(
      project_config: File.expand_path('../../test/integration/ansible/kitchen.yml', __dir__)
    )
  end

  let(:config) { Kitchen::Config.new(loader: loader) }
  let(:instance) { config.instances.first }
  let(:kitchen_root) { File.expand_path('../..', __dir__) }
  let(:log_file) { File.join(kitchen_root, '.kitchen', 'logs', "#{instance.name}.log") }

  before(:all) do
    Kitchen.logger = Kitchen.default_file_logger
  end

  after(:each) do
    instance.destroy
  end

  it 'successfully runs kitchen test' do
    expect { instance.test }.not_to raise_error
  end

  it 'verifies ansible playbook execution' do
    # Ensure the log directory exists
    FileUtils.mkdir_p(File.dirname(log_file))

    # Clear the log file before running converge
    File.write(log_file, '')

    # Run the converge action
    instance.converge

    # Read the log file
    log_content = File.read(log_file)

    # Perform checks on the log content
    expect(log_content).to include('Running Ansible Playbook')
    expect(log_content).to include('Ansible Playbook Complete!')

    # Check for the correct playbook path
    expect(log_content).to include('playbooks/playbook.yaml')

    # Check for extra vars in the command
    expect(log_content).to include('MARIO="MUSHROOM_KINGDOM"')
    expect(log_content).to include('LINK="HYRULE"')

    # Check for tags
    expect(log_content).to include('--tags "tag1"')

    # Check for skip tags
    expect(log_content).to include('--skip-tags "tag2"')

    # Check verbosity
    expect(log_content).to include('-v') # For verbosity 1

    # Check that the playbook was found and executed
    expect(log_content).not_to include('ERROR! the playbook: ./playbooks/playbook.yaml could not be found')
  end
end