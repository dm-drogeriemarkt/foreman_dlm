# Foreman Distributed Lock Manager
## Client Setup

To setup a client for automatic updates, you need to copy the script `updatelock` to the client and setup systemd to

* run `updatelock update` nightly
* run `updatelock release` after a reboot

The recommended way is to use a custom puppet module for this.
The script assumes that `/etc/updatelock/pre-update.d` contains scripts that should be run to check if the system is ready to acquire a lock.

To make sure the timer is configured successfully, you can run `systemctl list-timers`:

```
# systemctl list-timers
NEXT                          LEFT     LAST                          PASSED     UNIT                         ACTIVATES
Mon 2018-07-23 02:24:00 CEST  9h left  Thu 2018-07-19 04:24:00 CEST  3 days ago updatelock-update.timer      updatelock-update.service
Mon 2018-07-23 02:46:45 CEST  10h left Sun 2018-07-22 02:46:45 CEST  13h ago    systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service

2 timers listed.
Pass --all to see loaded but inactive timers, too.
```

### Install scripts manually

Make sure to copy `updatelock` to `/usr/local/sbin/updatelock`. Copy `updatelock-release.service`, `updatelock-update.service` and `updatelock-update.timer` to `/etc/systemd/system/`.
Then make sure to make the units known to systemd and enable them.

```
systemctl daemon-reload
systemctl enable updatelock-release.service
systemctl enable updatelock-update.timer
systemctl start updatelock-update.timer
```

### Install scripts via puppet

#### Install updatelock

```puppet
file { '/usr/local/sbin/updatelock':
  ensure  => file,
  mode    => '0700',
  owner   => 'root',
  group   => 'root',
  content => file("${module_name}/updatelock"),
}

file { '/etc/updatelock':
  ensure => directory,
}

file { '/etc/updatelock/pre-update.d':
  ensure => directory,
}
```

#### Install systemd files

This assumes that you use [puppet-systemd](https://github.com/camptocamp/puppet-systemd).

```puppet
systemd::unit_file { 'updatelock-release.service':
  ensure => file,
  source => "puppet:///modules/${module_name}/systemd/updatelock-release.service",
}

systemd::unit_file { 'updatelock-update.service':
  ensure => file,
  source => "puppet:///modules/${module_name}/systemd/updatelock-update.service",
}

systemd::unit_file { 'updatelock-update.timer':
  ensure  => file,
  source => "puppet:///modules/${module_name}/systemd/updatelock-update.timer",
}

service { 'updatelock-release.service':
  provider => 'systemd',
  name     => 'updatelock-release.service',
  enable   => true,
  require  => Exec['systemctl-daemon-reload'],
}

service { 'updatelock-update.timer':
  ensure   => running,
  provider => 'systemd',
  name     => 'updatelock-update.timer',
  enable   => true,
  require  => Exec['systemctl-daemon-reload'],
}
```
