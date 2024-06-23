#!/bin/bash
sudo apt update && sudo apt upgrade -y

sudo apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
sudo apt install python3-pip -y
sudo pip install yq

sudo useradd -m -s /bin/bash Prometheus 
sudo groupadd --system Prometheus  
sudo usermod -aG Prometheus Prometheus

sudo mkdir /var/lib/prometheus
sudo apt install prometheus
sudo mkdir -p /tmp/prometheus && cd /tmp/prometheus
sudo curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | xargs wget

sudo tar xvf prometheus*.tar.gz
cd prometheus*/
sudo mv prometheus promtool /usr/local/bin/

sudo mv prometheus.yml /etc/prometheus/prometheus.yml
sudo mv consoles/ console_libraries/ /etc/prometheus/

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

sudo mv prometheus.yml /etc/prometheus/prometheus.yml
sudo mv consoles/ console_libraries/ /etc/prometheus/

sudo systemctl daemon-reload && systemctl enable prometheusd && systemctl restart prometheusd

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
