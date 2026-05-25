#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "this script must be run as root" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l)  ARCH="armv7" ;;
    armv6l)  ARCH="armv6" ;;
    i386|i686) ARCH="386" ;;
    *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

echo "detecting latest node_exporter version..."
VERSION=$(curl -fsSL https://api.github.com/repos/prometheus/node_exporter/releases/latest \
    | grep -oP '"tag_name":\s*"v\K[^"]+')

if [[ -z "${VERSION:-}" ]]; then
    echo "failed to detect latest version" >&2
    exit 1
fi

echo "latest version: v${VERSION} (${ARCH})"

PKG="node_exporter-${VERSION}.linux-${ARCH}"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${PKG}.tar.gz"

useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter 2>/dev/null || true

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"

echo "downloading ${URL}..."
curl -fsSL -o "${PKG}.tar.gz" "$URL"
tar xzf "${PKG}.tar.gz"

if systemctl is-active --quiet node_exporter; then
    echo "stopping running node_exporter..."
    systemctl stop node_exporter
fi

install -m 0755 -o node_exporter -g node_exporter "${PKG}/node_exporter" /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=0.0.0.0:9100
Restart=always
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
sleep 2
systemctl status node_exporter --no-pager

echo
echo "node_exporter v${VERSION} installed and running on 0.0.0.0:9100"
