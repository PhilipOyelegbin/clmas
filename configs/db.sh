#!/usr/bin/bash
set -e

echo "========================= ⚙️ Updating and installing dependencies ========================="
sudo apt update -y
sudo apt install -y wget curl tar mysql-server

# ========================= NODE EXPORTER =========================
echo "========================= ⚙️ Installing Node Exporter ========================="
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
tar xvf node_exporter-1.9.1.linux-amd64.tar.gz
sudo mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/

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

# ========================= MYSQL EXPORTER =========================
echo "========================= ⚙️ Installing MySQL Exporter ========================="
cd /tmp
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo mv mysqld_exporter-0.15.1.linux-amd64/mysqld_exporter /usr/local/bin/

# Create MySQL exporter user
echo "========================= ⚙️ Configuring MySQL user ========================="
sudo mysql -e "CREATE USER IF NOT EXISTS 'mysqld_exporter'@'localhost' IDENTIFIED BY 'exporter_pass' WITH MAX_USER_CONNECTIONS 3;"
sudo mysql -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost'; FLUSH PRIVILEGES;"

# Create config file
sudo tee /etc/.mysqld_exporter.cnf > /dev/null <<EOF
[client]
user=mysqld_exporter
password=exporter_pass
EOF
sudo chown nobody:nogroup /etc/.mysqld_exporter.cnf
sudo chmod 600 /etc/.mysqld_exporter.cnf

# Create systemd service
sudo tee /etc/systemd/system/mysqld_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus MySQL Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/.mysqld_exporter.cnf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable mysqld_exporter
sudo systemctl start mysqld_exporter

echo "✅ MySQL Exporter running on port 9104"

# ========================= VERIFICATION =========================
echo "========================= 🚀 Verifying Exporters ========================="
echo "Node Exporter metrics (port 9100):"
curl -s http://localhost:9100/metrics | head -n 5 || echo "Node Exporter not responding."

echo
echo "MySQL Exporter metrics (port 9104):"
curl -s http://localhost:9104/metrics | head -n 5 || echo "MySQL Exporter not responding."

echo "🎉 Database server setup completed 🎉."