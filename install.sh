#!/bin/bash
MONIKER="ERN"

sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.21.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app
git checkout v1.3.0
make build

mkdir -p $HOME/.celestia-app/cosmovisor/genesis/bin
mv build/celestia-appd $HOME/.celestia-app/cosmovisor/genesis/bin/
rm -rf build

sudo ln -s $HOME/.celestia-app/cosmovisor/genesis $HOME/.celestia-app/cosmovisor/current -f
sudo ln -s $HOME/.celestia-app/cosmovisor/current/bin/celestia-appd /usr/local/bin/celestia-appd -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

sudo tee /etc/systemd/system/celestia.service > /dev/null << EOF
[Unit]
Description=celestia node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.celestia-app"
Environment="DAEMON_NAME=celestia-appd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.celestia-app/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia.service

celestia-appd config chain-id mocha-4
celestia-appd config keyring-backend test
celestia-appd config node tcp://localhost:26657

celestia-appd init $MONIKER --chain-id mocha-4

curl -Ls https://snapshots.kjnodes.com/celestia-testnet/genesis.json > $HOME/.celestia-app/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/celestia-testnet/addrbook.json > $HOME/.celestia-app/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@celestia-testnet.rpc.kjnodes.com:12059\"|" $HOME/.celestia-app/config/config.toml

sed -i -e "s|^target_height_duration *=.*|timeout_commit = \"11s\"|" $HOME/.celestia-app/config/config.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.002utia\"|" $HOME/.celestia-app/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "nothing"|' \
  $HOME/.celestia-app/config/app.toml

curl -L https://snapshots.kjnodes.com/celestia-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.celestia-app
[[ -f $HOME/.celestia-app/data/upgrade-info.json ]] && cp $HOME/.celestia-app/data/upgrade-info.json $HOME/.celestia-app/cosmovisor/genesis/upgrade-info.json

sudo systemctl start celestia.service && sudo journalctl -u celestia.service -f --no-hostname -o cat
