#!/usr/bin/bash
set -e

# ========================= PROMETHEUS SETUP =========================
echo "============================= ⚙️ Updating and installing dependencies =================================="
sudo apt update -y
sudo apt install -y wget curl tar

echo "============================= ⚙️ Downloading Prometheus =================================="
wget https://github.com/prometheus/prometheus/releases/download/v3.7.1/prometheus-3.7.1.linux-amd64.tar.gz

echo "============================= ⚙️ Extracting prometheus and move binaries =================================="
tar xvf prometheus-*.tar.gz
sudo mv prometheus-*/prometheus /usr/local/bin/
sudo mv prometheus-*/promtool /usr/local/bin/

echo "============================= ⚙️ Creating directories =================================="
sudo mkdir /etc/prometheus /var/lib/prometheus
sudo chown -R nobody:nogroup /etc/prometheus /var/lib/prometheus

echo "============================= ⚙️ Moving the default configuration file =================================="
sudo mv prometheus.yml /etc/prometheus/

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
sudo systemctl start prometheus

echo "✅ Prometheus running on ${curl ifconfig.me}:9090"

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
sudo systemctl start blackbox_exporter
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
sudo systemctl start grafana-server

echo "✅ Grafana running on ${curl ifconfig.me}:3000"

# ========================= VERIFICATION =========================
echo "============================= 🚀 Verifying =================================="
curl -s http://localhost:9090 | head -n 5 || echo "Prometheus not responding."
curl -s http://localhost:3000 | head -n 5 || echo "Grafana not responding."

echo "🎉 Monitoring server setup completed 🎉."