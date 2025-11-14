#!/usr/bin/bash
set -e

# Define variables
NODE_EXPORTER_VERSION=1.10.2

echo "========================= ⚙️ Updating and installing dependencies ========================="
sudo apt update -y
sudo apt install -y wget curl tar

# ========================= NODE EXPORTER =========================
echo "========================= ⚙️ Installing Node Exporter ========================="
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "✅ Node Exporter running on port 9100"

# ========================= VERIFICATION =========================
echo "========================= 🚀 Verifying Exporters ========================="
echo "Node Exporter metrics (port 9100):"
curl -s http://localhost:9100/metrics | head -n 5 || echo "Node Exporter not responding."

echo "🎉 App server setup completed 🎉."