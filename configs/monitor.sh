#!/bin/bash

set -e

# Setup variables
PROMETHEUS_VERSION=3.7.3
ALERTMANAGER_VERSION=0.29.0
BLACKBOX_EXPORTER_VERSION=0.27.0

# ========================= PROMETHEUS SETUP =========================
echo "============================= ⚙️ Updating and installing dependencies =================================="
sudo apt update -y
sudo apt install -y wget curl tar

echo "============================= ⚙️ Downloading Prometheus =================================="
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

echo "============================= ⚙️ Extracting prometheus and move binaries =================================="
tar xvf prometheus-*.tar.gz
sudo mv prometheus-*/prometheus /usr/local/bin/
sudo mv prometheus-*/promtool /usr/local/bin/

echo "============================= ⚙️ Creating directories =================================="
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown -R nobody:nogroup /etc/prometheus /var/lib/prometheus

echo "============================= ⚙️ Moving the default configuration file =================================="
sudo mv /tmp/prometheus.yml /etc/prometheus/
sudo mv /tmp/alert.rules.yml /etc/prometheus/

echo "============================= ⚙️ Creating Prometheus Service =================================="
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

echo "✅ Prometheus running on $(curl -s ifconfig.me):9090"

# ========================= ALERTMANAGER SETUP =========================
echo "============================= ⚙️ Download Alertmanager =================================="
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz

echo "============================= ⚙️ Extract the tarball =================================="
tar -xvf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
sudo mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager /usr/local/bin/
sudo mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/amtool /usr/local/bin/

echo "============================= ⚙️ Create Alertmanager Config File =================================="
if [ ! -d "/etc/alertmanager" ]; then
  sudo mkdir -p /etc/alertmanager
else
  echo "Directory /etc/alertmanager already exists."
fi

if [ ! -d "/var/lib/alertmanager" ]; then
  sudo mkdir -p /var/lib/alertmanager
else
  echo "Directory /var/lib/alertmanager already exists."
fi

if id "alertmanager" &>/dev/null; then
  echo "User 'alertmanager' already exists."
else
  echo "Creating user 'alertmanager'..."
  sudo useradd --no-create-home --shell /bin/false alertmanager
  echo "User 'alertmanager' created successfully."
fi

sudo mv /tmp/alertmanager.yml /etc/alertmanager/
sudo chown -R alertmanager:alertmanager /etc/alertmanager/ /var/lib/alertmanager
sudo chmod -R 755 /etc/alertmanager /var/lib/alertmanager

echo "============================= ⚙️ Create Alertmanager Service =================================="
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
User=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager/data

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl restart alertmanager
sudo systemctl status alertmanager

echo "✅ Alertmanager running on $(curl -s ifconfig.me):9093"

# ========================= BLACKBOX EXPORTER SETUP =========================
echo "============================= ⚙️ Download and extract blackbox exporter =================================="
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz
tar xvf blackbox_exporter-0.25.0.linux-amd64.tar.gz
sudo mv blackbox_exporter-*/blackbox_exporter /usr/local/bin/

echo "============================= ⚙️ Create a systemd service =================================="
sudo tee /etc/systemd/system/blackbox_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Blackbox Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/blackbox_exporter --config.file=/etc/blackbox_exporter.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "============================= ⚙️ Create blackbox config file =================================="
sudo tee /etc/blackbox_exporter.yml > /dev/null <<EOF
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      method: GET
      tls_config:
        insecure_skip_verify: true
EOF

sudo systemctl daemon-reload
sudo systemctl enable blackbox_exporter
sudo systemctl restart blackbox_exporter
sudo systemctl status blackbox_exporter

echo "✅ Blackbox enabled"

# ========================= GRAFANA SETUP =========================
echo "============================= ⚙️ Add the Grafana GPG key and repository =================================="
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt-get install -y apt-transport-https
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

echo "============================= ⚙️ Update the package list and install Grafana =================================="
sudo apt update
sudo apt install grafana -y
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

echo "✅ Grafana running on $(curl -s ifconfig.me):3000"

# ========================= VERIFICATION =========================
echo "============================= 🚀 Verifying =================================="
curl -s http://localhost:9090 | head -n 5 || echo "Prometheus not responding."
curl -s http://localhost:3000 | head -n 5 || echo "Grafana not responding."

echo "🎉 Monitoring server setup completed 🎉."