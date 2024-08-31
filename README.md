# kitchen-yansible-pusher

![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/main.yml/badge.svg)
![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/release.yml/badge.svg)
![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/integration.yml/badge.svg)

The goal of this project was to make a modern and minimalistic test-kitchen provisioner for Ansible, that works in push mode instead of pull mode.

From using Ansible for a while, I believe Gems like [kitchen-ansible](https://github.com/neillturner/kitchen-ansible) and [kitchen-ansiblepush](https://github.com/ahelal/kitchen-ansiblepush) both do too much, as well as seem to have been abandoned by their respective creators.

By doing less, and expecting the user to install their own Ansible, provide their configuration in the form of environment variables, an `ansible.cfg` file or tags and running only in `push` mode(normal mode) we free ourselves from having to support all kinds of installation methods across platforms and in a way future proof ourselves.

## Installation

Edit your Gemfile to look like this, or install it like this `gem install kitchen-yansible-pusher`

```ruby
# Install from Github
gem 'kitchen-yansible-pusher',
    git: 'https://github.com/jmtx1020/kitchen-yansible-pusher.git',
    branch: 'main'

# Install via RubyGems
gem 'kitchen-yansible-pusher', '~> 0.1.0'
```

## Usage

Keeping simplicity in mind, this kitchen-provisioner has minimal options to get going.
```yaml
---
driver:
  name: docker

platforms:
  - name: ubuntu-22.04

provisioner:
  name: yansible_pusher
  playbook: "/path/to/playbook.yaml"
  config: "/path/to/ansible.cfg"
  env_vars:
    MARIO: "MUSHROOM_KINGDOM"
    LINK: "HYRULE_KINGDOM"
  tags:
    - tag1
    - tag2
  skip_tags:
    - tag3
    - tag4
  verbosity: 1
  vault_password_file: "/path/to/vault.password"
  username: username
  private_key: "/path/to/private.key"

suites:
  - name: default

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jmtx1020/kitchen-yansible-pusher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
