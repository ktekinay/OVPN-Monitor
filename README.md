# OVPN-Monitor
A GUI to monitor an OpenVPN Server

## What You Need

- [Xojo](http://www.xojo.com) (the development language).
- An OpenVPN server.
- Add `management localhost <some port>` to the server config file to access its management features.

For example, if you add `management localhost 5555`, you should be able to `telnet 127.0.0.1 5555` on the local machine to access its management features.

## How To Use

Build the app using Xojo. Use settings to set the command that will access the management server. If running locally, this should start with `telnet`. If running remotely, set up SSH key authentication first and use something like `ssh vpn.server 'telnet 127.0.0.1 5555'`. Verify the command by trying it in a terminal first.

## Who Did This

Kem Tekinay, MacTechnologies Consulting
ktekinay at mactechnologies dot com

## Release Notes

1.0 (Oct. 12, 2016)

- Initial release.
