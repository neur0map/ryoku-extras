# VPN & Networking

VPN basics and desktop clients for Ryoku: WireGuard, OpenVPN, IPsec/IKEv2,
Proton VPN, Mullvad VPN, and Cloudflare WARP. Install it from **Settings,
Extras, VPN & Networking, Install all**, or install individual tools from the
bundle card.

## Core

| Tool | What it is | Source |
| --- | --- | --- |
| wireguard-tools | Command-line tools for WireGuard VPN tunnels. | pacman |
| openvpn | OpenVPN client and server for classic VPN profiles. | pacman |
| networkmanager-openvpn | NetworkManager integration for OpenVPN profiles. | pacman |
| networkmanager-strongswan | NetworkManager integration for IPsec/IKEv2 VPNs. | pacman |

## Services / Clients

| Client | What it is | Source |
| --- | --- | --- |
| proton-vpn-gtk-app | Official Proton VPN GTK desktop client. | pacman |
| mullvad-vpn-bin | Mullvad VPN desktop client. | AUR |
| cloudflare-warp-bin | Cloudflare WARP client and `warp-cli`. | AUR |

## Notes

- Provider clients still require a valid account or service setup after install.
- NetworkManager VPN plugins may need NetworkManager restarted or a logout/login
  before every UI integration appears.
- All tools are separate bundle items, so users can install only the VPN stack
  or provider client they actually use.
