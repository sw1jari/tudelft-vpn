#!/bin/sh
# Installs split DNS for eduVPN: a local dnsmasq on 127.0.0.1:53 sends the
# VPN's own domains (tudelft.net) to TU Delft's DNS and everything else to the
# normal connection's DNS. Run as root. Undo with: install-dns.sh --uninstall
set -e
cd "$(dirname "$0")"

if [ "$1" = "--uninstall" ]; then
    rm -f /etc/NetworkManager/conf.d/90-tudelft-vpn-dns.conf
    systemctl disable --now tudelft-vpn-dns.service 2>/dev/null || true
    rm -f /etc/systemd/system/tudelft-vpn-dns.service /etc/tudelft-vpn-dns.conf \
        /usr/local/bin/tudelft-vpn-dns-update
    rm -rf /run/tudelft-vpn-dns
    systemctl daemon-reload
    # NetworkManager writes resolv.conf again from here on
    rm -f /etc/resolv.conf
    systemctl restart NetworkManager
    echo "removed; reconnect eduVPN so the split script writes DNS itself again"
    exit 0
fi

install -m 755 tudelft-vpn-dns-update /usr/local/bin/
install -m 644 tudelft-vpn-dns.conf /etc/
install -m 644 tudelft-vpn-dns.service /etc/systemd/system/
install -m 755 50-eduvpn-split /etc/NetworkManager/dispatcher.d/
systemctl daemon-reload
systemctl enable --now tudelft-vpn-dns.service
sleep 1

# Only switch the system over once the forwarder answers
if ! nslookup -timeout=3 example.com 127.0.0.1 >/dev/null 2>&1; then
    echo "the forwarder on 127.0.0.1 doesn't answer, leaving resolv.conf alone" >&2
    echo "check: journalctl -u tudelft-vpn-dns" >&2
    exit 1
fi

install -m 644 90-tudelft-vpn-dns.conf /etc/NetworkManager/conf.d/
systemctl reload NetworkManager
printf '# tudelft-vpn-dns: local forwarder, see /etc/tudelft-vpn-dns.conf\nnameserver 127.0.0.1\n' > /etc/resolv.conf.new
mv /etc/resolv.conf.new /etc/resolv.conf
echo "installed; tudelft.net now resolves while eduVPN is up"
