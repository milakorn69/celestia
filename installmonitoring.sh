#!/bin/bash
sudo apt update && sudo apt upgrade -y

sudo wget $(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest |grep "tag_name" | awk '{print "https://github.com/prometheus/node_exporter/releases/download/" substr($2, 2, length($2)-3) "/node_exporter-" substr($2, 3, length($2)-4) ".linux-amd64.tar.gz"}')

sudo tar xvf node_exporter-*.tar.gz
sudo cp ./node_exporter-*.linux-amd64/node_exporter /usr/local/bin/

sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter

sudo rm -rf ./node_exporter*

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
  Description=Node Exporter
  Wants=network-online.target
  After=network-online.target
[Service] 
  User=node_exporter
  Group=node_exporter
  Type=simple
  ExecStart=/usr/local/bin/node_exporter
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service

sudo wget $(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest |grep "tag_name" | awk '{print "https://github.com/prometheus/prometheus/releases/download/" substr($2, 2, length($2)-3) "/prometheus-" substr($2, 3, length($2)-4) ".linux-amd64.tar.gz"}')

sudo tar xvf prometheus-*.tar.gz
sudo cp ./prometheus-*.linux-amd64/prometheus /usr/local/bin/
sudo cp ./prometheus-*.linux-amd64/promtool /usr/local/bin/ 
sudo cp -r ./prometheus-*.linux-amd64/consoles /etc/prometheus
sudo cp -r ./prometheus-*.linux-amd64/console_libraries /etc/prometheus

sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo mkdir /var/lib/prometheus

sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

sudo rm -rf ./prometheus*

sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=Prometheus
Group=Prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \
--web.listen-address=0.0.0.0:9090 \
--web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cd /etc/prometheus
sudo chown prometheus:prometheus rules.yml

sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service

sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

echo "deb https://packages.grafana.com/enterprise/deb estable main "| sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo useradd -m -s /bin/bash grafana
sudo groupadd --system Grafana
sudo usermod -aG Grafana grafana

sudo apt-get install -y adduser libfontconfig1
sudo wget https://dl.grafana.com/enterprise/release/grafana-enterprise_9.3.2_amd64.deb
sudo dpkg -i grafana-enterprise_9.3.2_amd64.deb

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server.service
