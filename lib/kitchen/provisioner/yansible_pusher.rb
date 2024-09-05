# frozen_string_literal: true

require 'kitchen/provisioner/base'
require 'kitchen/errors'
require_relative '../yansible/pusher/version'
require 'yaml'
require 'English'

module Kitchen
  module Provisioner
    # YansiblePusher is a Kitchen provisioner plugin for Ansible.
    # It allows you to use Ansible playbooks to provision test instances in Test Kitchen.
    #
    # @example Using YansiblePusher in your kitchen.yml
    #   provisioner:
    #     name: yansible_pusher
    #     playbook: playbooks/playbook.yml
    #     env_vars:
    #       MARIO: "MUSHROOM_KINGDOM"
    #       LINK: "HYRULE_KINGDOM"
    #
    # @author <MY_NAME>
    # @version 0.1.0
    # @see https://github.com/jmtx1020/kitchen-yansible-pusher Documentation/Homepage
    # @see https://github.com/jmtx1020/kitchen-yansible-pusher/issues For bug reports and feature requests
    class YansiblePusher < Kitchen::Provisioner::Base # rubocop:disable Metrics/ClassLength
      kitchen_provisioner_api_version 2
      plugin_version Kitchen::Yansible::Pusher::VERSION

      default_config :playbook, nil
      default_config :config, nil
      default_config :env_vars, {}
      default_config :extra_flags, []
      default_config :tags, []
      default_config :skip_tags, []
      default_config :verbosity, 1
      default_config :vault_password_file, nil
      default_config :username, nil
      default_config :private_key, nil
      default_config :windows_config, nil

      attr_reader :sandbox_path

      def install_command
        # No initialization command needed on the remote instance
        nil
      end

      def init_command
        # No initialization command needed on the remote instance
        nil
      end

      def prepare_command
        # No preparation command needed on the remote instance
        nil
      end

      def run_command
        info("Running Ansible Playbook: #{config[:playbook]}")
        begin
          create_sandbox
          run_ansible
          info('Ansible Playbook Complete!')
        ensure
          cleanup_sandbox
        end
        ensure_windows_exit_code if windows_instance?
      end

      private

      def run_ansible
        command = build_ansible_command
        info("Running Ansible Command: #{command}")
        system(ansible_env_vars, command)
        raise Kitchen::ActionFailed, 'Ansible playbook execution failed' unless $CHILD_STATUS.success?
      end

      def create_inventory
        inventory = build_inventory
        write_inventory_file(inventory)
      end

      def build_inventory
        state = instance.transport.instance_variable_get(:@connection_options)
        {
          'all' => {
            'hosts' => {
              instance.name => build_host_config(state)
            }
          }
        }
      end

      def build_host_config(state)
        if windows_instance?
          build_windows_config(state)
        else
          build_linux_config(state)
        end
      end

      def build_linux_config(state)
        {
          'ansible_host' => state[:hostname],
          'ansible_port' => state[:port],
          'ansible_user' => config[:username] || state[:username]
        }
      end

      def build_windows_config(state)
        uri = URI(state[:endpoint])
        defaults = default_windows_config(state, uri)
        user_windows_config(defaults)
      end

      def user_windows_config(defaults)
        user_config = (config[:winrm_config] || {}).transform_keys { |key| "ansible_#{key}" }
        defaults.merge(user_config.compact)
      end

      def default_windows_config(state, uri)
        { 'ansible_host' => uri.host,
          'ansible_port' => state[:port] || uri.port,
          'ansible_user' => state[:user],
          'ansible_password' => state[:password],
          'ansible_connection' => 'winrm',
          'ansible_winrm_server_cert_validation' => 'ignore',
          'ansible_winrm_transport' => 'ssl',
          'ansible_winrm_scheme' => uri.scheme }
      end

      def write_inventory_file(inventory)
        inventory_file = File.join(sandbox_path, 'inventory.yml')
        File.write(inventory_file, inventory.to_yaml)
        inventory_file
      end

      def build_ansible_command
        cmd = ['ansible-playbook']
        ansible_options.each { |option| cmd = send(option, cmd) }
        cmd << "--inventory #{create_inventory}"
        cmd << config[:playbook]
        cmd.join(' ')
      end

      def ansible_options
        %i[
          ansible_use_private_key
          ansible_use_vault_password_file
          ansible_extra_flags
          ansible_tags
          ansible_skip_tags
          ansible_verbosity
        ]
      end

      def ansible_env_vars
        env = ENV.to_h.dup
        config[:env_vars]&.each do |key, value|
          env[key.to_s] = value.to_s unless value.nil?
        end
        env['ANSIBLE_CONFIG'] = config[:config] unless config[:config].nil?
        env
      end

      def ansible_extra_flags(cmd)
        cmd << config[:extra_flags].join(' ') unless config[:extra_flags].empty?
        cmd
      end

      def ansible_tags(cmd)
        cmd << "--tags \"#{config[:tags].join(',')}\"" unless config[:tags].empty?
        cmd
      end

      def ansible_skip_tags(cmd)
        cmd << "--skip-tags \"#{config[:skip_tags].join(',')}\"" unless config[:skip_tags].empty?
        cmd
      end

      def ansible_use_private_key(cmd)
        if config[:private_key]
          cmd << "--private-key #{config[:private_key]}"
        else
          state = instance.transport.instance_variable_get(:@connection_options)
          cmd << "--private-key #{state[:keys][0]}" if state.key?(:keys)
        end
        cmd
      end

      def ansible_use_vault_password_file(cmd)
        cmd << "--vault-password-file #{config[:vault_password_file]}" unless config[:vault_password_file].nil?
        cmd
      end

      def ansible_verbosity(cmd)
        cmd << "-#{'v' * config[:verbosity]}" if config[:verbosity] >= 1
        cmd
      end

      def create_sandbox
        @sandbox_path = Dir.mktmpdir('kitchen-yansible-pusher')
        info("Sandbox created at: #{@sandbox_path}")
      rescue StandardError => e
        error("Failed to create sandbox: #{e.message}")
        raise
      end

      def cleanup_sandbox
        if sandbox_path && Dir.exist?(sandbox_path)
          FileUtils.remove_entry(sandbox_path)
          info("Sandbox cleaned up: #{sandbox_path}")
        else
          info('No sandbox to clean up or sandbox already removed')
        end
      rescue StandardError => e
        error("Failed to clean up sandbox: #{e.message}")
        raise
      end

      def windows_instance?
        instance.transport.instance_variable_get(:@connection_options).key?(:endpoint)
      end

      # Ensures proper exit code handling for Windows instances in Test Kitchen.
      #
      # @return [String] A PowerShell command string to be executed on the remote Windows system.
      #
      # This method is only called for Windows instances. It returns a PowerShell command that:
      # 1. Outputs the status of the last command ($?)
      # 2. Exits with 0 if the last command succeeded, or 1 if it failed
      #
      # This approach addresses a specific issue with Test Kitchen's WinRM transport,
      # where it expects a command string to execute rather than a boolean result.
      # It ensures that the correct exit code is returned to Test Kitchen.
      def ensure_windows_exit_code
        '$?; if($?) { exit 0 } else { exit 1 }'
      end
    end
  end
end
