# VPN

A community bar widget for the [Ryoku](https://ryoku.dev) desktop. It rides the
top bar as a single Material mark that shows your VPN at a glance and toggles it
with a click.

![VPN widget on the bar](assets/preview-widget.png)

## What it does

- Polls NetworkManager (`nmcli`) for the active connection table and reflects
  live state on the bar:
  - **`vpn_lock`** in the theme accent when a VPN connection is up.
  - **`vpn_key_off`** in the dim ink when none is.
- When a VPN is up, it can print the connection name beside the mark.
- Remembers the last VPN it saw up, so a click can bring it back after it drops.

A connection counts as a VPN when its `nmcli` TYPE is one of the configured
types (`vpn`, `wireguard`, `tun` by default), which covers OpenVPN/IKEv2 (`vpn`),
WireGuard (`wireguard`), and plain tunnels (`tun`).

## Click behaviour

Clicking the mark toggles the VPN:

- **Connected** -> `nmcli connection down <name>` brings the active VPN down.
- **Disconnected** -> `nmcli connection up <last VPN>` brings the last one it saw
  back up.
- **Nothing known** (never seen a VPN up this session) -> no-op; it logs a line
  and waits until a VPN appears in the connection table.

State refreshes immediately after a toggle, and otherwise on the poll cadence.
Hovering the mark shows the connection name and what a click will do.

## Settings

| Key | Type | Default | What it does |
|---|---|---|---|
| `poll` | int (2..60) | `5` | Seconds between `nmcli` polls. |
| `showName` | toggle | `true` | Show the connection name beside the mark. |
| `types` | text | `vpn,wireguard,tun` | `nmcli` TYPEs that count as a VPN (comma or space separated). |

## Requirements

- **NetworkManager** with the `nmcli` command on `PATH`. The widget runs
  `nmcli` to read the active connections and to bring a VPN up or down, so
  NetworkManager must be managing the VPN connection you want to toggle.

## License

MIT (c) neur0map. See [LICENSE](LICENSE).
