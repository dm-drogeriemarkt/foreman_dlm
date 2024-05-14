# Foreman Distributed Lock Manager

[<img src="https://opensourcelogos.aws.dmtech.cloud/dmTECH_opensource_logo%401x.svg" height="21" width="130">](https://www.dmtech.de/)

This is a plugin for Foreman that allows Foreman to act as a distributed lock manager.
Updates are key to security, but updates of an operating system are hard to apply and existing tools are hard to manage at scale. This might lead to a large drift between important security updates becoming available and all your hosts being successfully patched. Security experts recommend to install updates as soon as they come available. The ability to easily update software is the most effective way to improve server security. Automation is key to ensure this goal is reached.
This plug-in aims to provide painless updates of the operating system. This keeps your company more secure and frees up resources of your operations team for more important tasks.

With this plugin servers can acquire a lock in Foreman to ensure only one server in a cluster installs updates at the same time. This can successfully prevent service disruptions.

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | -------------- |
| >= 1.15         | ~> 0.1         |
| >= 1.17         | ~> 1.0         |
| >= 3.0          | ~> 2.0         |
| >= 3.9          | ~> 3.0         |

## Installation

See [Plugins install instructions](https://theforeman.org/plugins/)
for how to install Foreman plugins.
On Enterprise Linux, you need to install the package `tfm-rubygem-foreman_dlm`.

## Usage

Servers are identified by their puppet certificates. Support for using subscription-manager certificates is planned, but currently not implemented.
Here you find a usage example using `curl` that shows how to acquire the `test` lock. The lock will be created if it does not exist.

```
curl -D - -H 'Content-Type: application/json' --key $(puppet config print hostprivkey) --cert $(puppet config print hostcert) -X PUT https://foreman.example.com/api/dlmlocks/test/lock
```

Use the HTTP method `GET` to show a lock, `PUT` to acquire a lock and `DELETE` to release a lock.
Foreman will respond with the HTTP status code `200 OK` if the action was successful and `412 Precondition Failed` if the lock could not be acquired or release. This may happen, if the lock is taken by another host.

To process the HTTP status code in a bash script, you can do something like this:

```
curl --write-out %{http_code} -H 'Content-Type: application/json' -sS -o /dev/null -X PUT --key $(puppet config print hostprivkey) --cert $(puppet config print hostcert) https://foreman.example.com/api/dlmlocks/test/lock
```

## Client setup

The Foreman plugin itself just provides a central lock manager. To setup automatic updates, you need to run a script on your clients that tries to acquire a lock in Foreman and takes care of the actual patching process.
The `contrib/client` directory in this repo contains a basic script and systemd units that should allow you to get started.
A [client counterpart](https://github.com/schlitzered/foreman_dlm_updater) written in Python has been developed by the community to make it easier to use this Foreman plug-in.

## Note about curl on macOS

macOS uses curl with a different ssl library which gets problematic testing the cert-signed requests.
The Error:
`WARNING: SSL: CURLOPT_SSLKEY is ignored by Secure Transport. The private key must be in the Keychain.`

A fix is described here:
https://github.com/curl/curl/issues/283

```
$ brew install curl --with-openssl
$ brew link curl --force
```

After that `curl --version` changes from

```
$ curl --version
curl 7.54.0 (x86_64-apple-darwin16.0) libcurl/7.54.0 SecureTransport zlib/1.2.8
```

to

```
$ curl --version
curl 7.56.1 (x86_64-apple-darwin16.7.0) libcurl/7.56.1 OpenSSL/1.0.2m zlib/1.2.8
```

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2018 dmTECH GmbH, [dmtech.de](https://www.dmtech.de/)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
