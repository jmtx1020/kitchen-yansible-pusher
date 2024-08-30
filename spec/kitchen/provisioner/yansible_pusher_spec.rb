require 'kitchen/provisioner/yansible_pusher'
require 'kitchen/transport/dummy'
require 'kitchen/verifier/dummy'
require 'kitchen/driver/dummy'
require 'logger'
require 'tmpdir'

describe Kitchen::Provisioner::YansiblePusher do
  let(:config) do
    {
      playbook: 'playbook.yml',
      extra_vars: { 'MARIO' => 'MUSHROOM_KINGDOM' },
      tags: ['tag1', 'tag2'],
      skip_tags: ['skip1'],
      verbosity: 2,
      vault_password_file: '/path/to/vault/password',
      username: 'test_user',
      private_key: '/path/to/private/key'
    }
  end

  let(:platform) { Kitchen::Platform.new(name: 'ubuntu') }
  let(:suite) { Kitchen::Suite.new(name: 'suite') }
  let(:state) { { hostname: 'test.host', port: 22, username: 'default_user' } }
  let(:transport) { Kitchen::Transport::Dummy.new }
  let(:driver) { Kitchen::Driver::Dummy.new }
  let(:verifier) { Kitchen::Verifier::Dummy.new }
  let(:lifecycle_hooks) { double('lifecycle_hooks') }
  let(:logger) { Logger.new(STDOUT) }

  let(:instance) do
    instance_double(Kitchen::Instance).tap do |inst|
      allow(inst).to receive(:name).and_return('default-ubuntu')
      allow(inst).to receive(:transport).and_return(transport)
      allow(inst).to receive(:lifecycle_hooks).and_return(lifecycle_hooks)
      allow(inst).to receive(:logger).and_return(logger)
    end
  end

  let(:provisioner) { described_class.new(config) }

  before do
    allow(provisioner).to receive(:instance).and_return(instance)
    allow(transport).to receive(:connection).and_return(double('connection'))
    allow(provisioner).to receive(:run_ansible).and_return(nil)
    allow(transport).to receive(:instance_variable_get).with(:@connection_options).and_return(state)
    
    # Create a temporary directory for the sandbox
    @sandbox_path = Dir.mktmpdir
    allow(provisioner).to receive(:sandbox_path).and_return(@sandbox_path)
  end

  after do
    # Clean up the temporary directory
    FileUtils.remove_entry(@sandbox_path)
  end

  describe '#run_command' do
    it 'creates sandbox, runs ansible, and cleans up sandbox' do
      expect(provisioner).to receive(:create_sandbox)
      expect(provisioner).to receive(:run_ansible)
      expect(provisioner).to receive(:cleanup_sandbox)
      provisioner.run_command
    end
  end

  describe '#build_ansible_command' do
    it 'builds the correct ansible-playbook command' do
      allow(provisioner).to receive(:create_inventory).and_return('/path/to/inventory.yml')
      command = provisioner.send(:build_ansible_command)
      expect(command).to include('ansible-playbook')
      expect(command).to include("MARIO=\"MUSHROOM_KINGDOM\"")
      expect(command).to include('--tags "tag1tag2"')
      expect(command).to include('--skip-tags "skip1"')
      expect(command).to include('-vv')
      expect(command).to include('--vault-password-file /path/to/vault/password')
      expect(command).to include('--private-key /path/to/private/key')
      expect(command).to include('--inventory /path/to/inventory.yml')
      expect(command).to include('playbook.yml')
    end
  end

  describe '#create_inventory' do
    it 'creates an inventory file with correct content' do
      inventory_file = provisioner.send(:create_inventory)
      expect(File.exist?(inventory_file)).to be true

      inventory_content = YAML.load_file(inventory_file)
      expect(inventory_content['all']['hosts']['default-ubuntu']).to eq({
        'ansible_host' => 'test.host',
        'ansible_port' => 22,
        'ansible_user' => 'test_user'
      })
    end
  end
end