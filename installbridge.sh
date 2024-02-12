#!/bin/bash
git clone https://github.com/celestiaorg/celestia-node && cd celestia-node

git checkout tags/v0.12.4

make build

make install

make cel-key

mv $HOME/celestia-node/cel-key /usr/local/bin/ 
cel-key add bridge_wallet --keyring-backend test --node.type bridge --p2p.network mocha
cel-key list --node.type bridge --keyring-backend test --p2p.network mocha
celestia bridge init \
  --p2p.network mocha \
  --core.ip http://localhost \
  --core.rpc.port 26657 \
  --core.grpc.port 9090 \
  --gateway \
  --gateway.addr 0.0.0.0 \
  --gateway.port 29659 \
  --rpc.addr 0.0.0.0 \
  --rpc.port 29658 \
  --keyring.accname bridge_wallet

tee <<EOF >/dev/null /etc/systemd/system/celestia-bridge.service
[Unit]
Description=celestia-bridge Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia) bridge start \
  --p2p.network mocha \
  --gateway \
  --gateway.addr 0.0.0.0 \
  --gateway.port 29659 \
  --metrics.tls=false \
  --metrics \
  --metrics.endpoint otel.celestia.tools:4318
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable celestia-bridge
systemctl restart celestia-bridge && journalctl -u celestia-bridge -f -o cat
