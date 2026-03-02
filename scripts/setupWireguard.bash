#!/usr/bin/env bash
# This file is create to help setting up WireGuard peer connections

WireGuardConnectionName=$1
WANIPofRouter=$2
PublicKeyFromRouter=$3

function syntax() {
  echo "Syntax: $0 wireguard-connection-name WAN-IP-of-router public-key-from-router"
}

if [[ "${PublicKeyFromRouter}" == "" ]]; then
  syntax
  exit 1
fi

PrivateKey=$(wg genkey)
PublicKey=$(echo "${PrivateKey}" | wg pubkey)
WireGuardConnectionFileName=${WireGuardConnectionName}.conf

cat <<EOL >"${WireGuardConnectionFileName}"
[Interface]
ListenPort = 51820
PrivateKey = ${PrivateKey}
Address = 10.3.254.20/32
DNS = 1.1.1.1
PostUp = ip route add 192.168.88.0/24 dev ${WireGuardConnectionName}
PostUp = ip route add    10.25.0.0/24 dev ${WireGuardConnectionName}
Table = off

[Peer]
PublicKey = ${PublicKeyFromRouter}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${WANIPofRouter}:51820
EOL

echo "Update the WireGuard section of the mikrotik module in main.tf to look something like this:"
cat <<EOL
  wireguard = {
    peer = {
      "${USER}" = {
        ip_address = "10.3.254.20"
        public_key = "${PublicKey}"
      }
    }
  }
EOL
echo
echo "Then run the terraform apply again to create your configuration as a peer in the router"
echo

echo "A WireGuard configuration is save to a file named ${WireGuardConnectionFileName}"
echo "Copy this file to /etc/wireguard/"
echo "Then start the connection with \"wg-quick up ${WireGuardConnectionName}\""
