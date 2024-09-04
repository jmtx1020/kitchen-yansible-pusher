# kitchen-yansible-pusher

![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/main.yml/badge.svg)
![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/release.yml/badge.svg)
![main](https://github.com/jmtx1020/kitchen-yansible-pusher/actions/workflows/integration.yml/badge.svg)

The goal of this project was to make a modern and minimalistic test-kitchen provisioner for Ansible, that works in push mode instead of pull mode.

From using Ansible for a while, I believe Gems like [kitchen-ansible](https://github.com/neillturner/kitchen-ansible) and [kitchen-ansiblepush](https://github.com/ahelal/kitchen-ansiblepush) both do too much, as well as seem to have been abandoned by their respective creators.

By doing less, and expecting the user to install their own Ansible, provide their configuration in the form of environment variables, an `ansible.cfg` file, tags, CLI flags and running only in `push` mode(normal mode) we free ourselves from having to support all kinds of installation methods across platforms and in a way future proof ourselves.

With that in mind, if there's something you think is missing please feel free to submit an issue or pull request and I will do my best to accomodate but keep in mind the goals of this project.

Additionally, these links to the documentation for `ansible-playbook` and `ansible.cfg` settings are here for convenience.

* [ansible-playbook](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html)
* [ansible-config](https://docs.ansible.com/ansible/latest/reference_appendices/config.html)

## Installation

Edit your Gemfile to look like this, or install it like this `gem install kitchen-yansible-pusher`

```ruby
# Install from Github
gem 'kitchen-yansible-pusher',
    git: 'https://github.com/jmtx1020/kitchen-yansible-pusher.git',
    branch: 'main'

# Install via RubyGems
gem 'kitchen-yansible-pusher', '~> 0.2.0'
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
  extra_flags:
    - --flush-cache
    - --timeout 60
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

### Usage on Windows - Requirements

To use this gem and with a Windows target you need to install [PyWinRM](https://pypi.org/project/pywinrm/) as it is not part of the standard Ansible core distributed when you install through any methods.

```
pip install pywinrm
```

This error is known to occur when using the WinRM gem on Mac OS hosts due to the way Python forking works.

```
objc[78682]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.
```

The solution is to run this command and then you should be able to run your role successfully.

```
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

### Windows Usage - Configuration

This provisoner infers the settings needed to connect to the box using the connection data from the instance, however if you need to overwrite any of these settings they are overwritable by specifying these values.

```yaml
provisioner:
  name: yansible_pusher
  winrm:
    host: ""
    port: 1234
    user: username1
    password: SuperSecurePassword!
    connection: 'winrm'
    server_cert_validation: 'ignore'
    transport: 'ssl'
    scheme: 'http'
```

More information about these settings can be found [here](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jmtx1020/kitchen-yansible-pusher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
