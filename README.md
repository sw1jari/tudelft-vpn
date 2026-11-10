# tudelft-vpn

TU Delft eduVPN on Linux, with only TU Delft traffic going through the VPN.

TU Delft's eduVPN profile sends all traffic through the university, including personal browsing and DNS lookups. This repo has two parts:

| File | What it does |
|---|---|
| [`50-eduvpn-split`](50-eduvpn-split) | NetworkManager dispatcher script. When eduVPN connects, only TU Delft networks go through the tunnel; everything else uses your normal connection and its DNS |
| [`tudelft-vpn`](tudelft-vpn) | Command to connect or disconnect, with notifications. Handy from dmenu |

## Split tunnel

The script runs on its own whenever the NetworkManager connection named `eduVPN` comes up or goes down. The eduVPN app itself is left alone.

With the VPN on:

| Traffic | Goes through |
|---|---|
| TU Delft networks (`131.180.0.0/16`, `130.161.0.0/16`, `145.94.0.0/16`) | The VPN |
| Everything else over IPv4 | Your normal connection |
| DNS | Your normal connection's DNS servers |
| Your home network | Your normal connection, so printers and the like keep working |
| IPv6 | Your normal connection if it has IPv6, otherwise blocked so it can't leak into the tunnel |

How it works: the server pushes more than a default route (also `::/3`, `2000::/4` and parts of common home networks), so overriding the default route alone isn't enough. The script copies every route that doesn't use the VPN into its own routing table, and adds rules so that only TU Delft addresses look up the normal table with the VPN routes in it.

Things that change compared to the full tunnel:
- Sites that recognise TU Delft by IP address, like journal publishers, no longer see you as on campus. Use "access through your institution" and log in with your NetID instead.
- Hostnames that only resolve inside the TU Delft network won't resolve. GitLab, DAIC and Mattermost resolve publicly and work.

Install:

```sh
sudo install -m 755 -o root 50-eduvpn-split /etc/NetworkManager/dispatcher.d/
```

Then reconnect eduVPN. Check that it works:

```sh
ip route get 131.180.0.1   # dev tun0
ip route get 1.1.1.1       # your normal interface, table 4711
curl -4 ifconfig.me        # your normal public IP
```

Uninstall by removing the file and reconnecting.

## tudelft-vpn

```sh
tudelft-vpn        # connect, or disconnect when already connected
tudelft-vpn on     # only connect
tudelft-vpn off    # only disconnect
```

It shows "Connecting..." and then "Connected" in one notification, and errors from eduvpn-cli as an urgent one. When your eduVPN login has expired, the TU Delft login page opens in the browser first.

It connects to the first server in `eduvpn-cli list`, so add TU Delft once in the eduVPN app first.

Install:

```sh
cp tudelft-vpn ~/.local/bin/
```

[dwm-status](https://github.com/sw1jari/dwm-status) has a `vpn` entry that shows `eduVPN...` while connecting and `eduVPN` once connected.

## Requirements

NetworkManager with the eduVPN Linux client (`eduvpn-gui` and `eduvpn-cli`), iproute2, and dunst or libnotify for notifications. Tested with the OpenVPN profile TU Delft's "Studenten" profile uses; eduVPN's WireGuard setup puts its routes in a separate table, which the split script doesn't handle.

## License

MIT
