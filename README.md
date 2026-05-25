# node-exporter-autoinstall

A tiny installer script for [Prometheus Node Exporter](https://github.com/prometheus/node_exporter).

It handles the boring boilerplate so you can get from a fresh box to a running exporter in about a minute.

## What it does

- Detects the latest `node_exporter` release from GitHub automatically
- Auto-detects CPU architecture (`amd64` / `arm64` / `armv7` / `armv6` / `386`)
- Creates a system user `node_exporter` with no login shell
- Installs the binary to `/usr/local/bin/node_exporter`
- Drops in a hardened `node_exporter.service` systemd unit and starts it

Re-running the script upgrades an existing install: it stops the service, swaps the binary, and starts it again.

## Requirements

- A Linux server with `systemd` (Ubuntu 20.04+, Debian 11+, etc.)
- Root access (run with `sudo`)
- `curl` and `tar` available on the system

## Usage

```bash
curl -fsSL -o install_node_exporter.sh https://github.com/m1337xx/node_exporter_autoinstall/raw/main/install_node_exporter.sh
sudo bash install_node_exporter.sh
```

Or, if you've cloned this repo:

```bash
sudo bash install_node_exporter.sh
```

> Run it with **bash**, not `sh`. The script uses bash-only features and will error out under dash/POSIX sh.

### After the script finishes

The exporter is listening on `0.0.0.0:9100`. Verify with:

```bash
curl -s http://127.0.0.1:9100/metrics | head
```

Then point your Prometheus server at it. A typical scrape config:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['your-host:9100']
```

## Troubleshooting

| Symptom | Try |
|---|---|
| `node_exporter` won't start | `sudo journalctl -u node_exporter -f` to see logs |
| `permission denied` on the binary | `sudo chmod u+x /usr/local/bin/node_exporter` |
| Prometheus can't scrape | Check firewall on port `9100` and that the bind address is reachable |
| `EUID: parameter not set` | You ran it with `sh`. Use `sudo bash install_node_exporter.sh` |
| Unsupported architecture | Check `uname -m` - only common linux arches are mapped |

## Uninstall

```bash
sudo systemctl disable --now node_exporter
sudo rm /etc/systemd/system/node_exporter.service
sudo rm /usr/local/bin/node_exporter
sudo userdel node_exporter
sudo systemctl daemon-reload
```

## Support

I don't provide personal support for this script! Please don't DM me with setup questions. If you run into an actual bug, feel free to [open an issue on GitHub](https://github.com/m1337xx/node_exporter_autoinstall/issues) and I'll take a look when I can.

## License

This script is offered as-is, no warranty. Node Exporter itself is Apache-2.0 licensed; see the [upstream repo](https://github.com/prometheus/node_exporter) for details.
