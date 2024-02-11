#!/bin/bash
sudo apt install -y curl git jq lz4 build-essential unzip

bash <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/go_install.sh")
source .bash_profile

sudo apt update && sudo apt upgrade -y

CELESTIA_PORT=11
echo "export WALLET="ERN" >> $HOME/.bash_profile
echo "export MONIKER="ERN" >> $HOME/.bash_profile
echo "export CHAIN_ID="mocha-4"" >> $HOME/.bash_profile
echo "export CELESTIA_PORT="${CELESTIA_PORT}"" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v1.6.0 
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install

cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git

cd celestia-app
celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
celestia-appd config keyring-backend os
celestia-appd config chain-id $CHAIN_ID
celestia-appd init $MONIKER --chain-id $CHAIN_ID

wget -O $HOME/.celestia-app/config/genesis.json https://testnet-files.itrocket.net/celestia/genesis.json
wget -O $HOME/.celestia-app/config/addrbook.json https://testnet-files.itrocket.net/celestia/addrbook.json

SEEDS="5d0bf034d6e6a8b5ee31a2f42f753f1107b3a00e@celestia-testnet-seed.itrocket.net:11656"
PEERS="daf2cecee2bd7f1b3bf94839f993f807c6b15fbf@celestia-testnet-peer.itrocket.net:11656"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml

sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CELESTIA_PORT}317\"%;
s%^address = \":8080\"%address = \":${CELESTIA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CELESTIA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CELESTIA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CELESTIA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CELESTIA_PORT}546\"%" $HOME/.celestia-app/config/app.toml

sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.celestia-app/config/app.toml

EXTERNAL_ADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external-address = \"\"/external-address = \"$EXTERNAL_ADDRESS:26656\"/" $HOME/.celestia-app/config/config.toml

sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.002utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.celestia-app/config/config.toml

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app 

sudo tee /etc/systemd/system/celestia-appd.service > /dev/null <<EOF
[Unit]
Description=celestia
After=network-online.target

[Service]
User=$USER
ExecStart=$(which celestia-appd) start --home $HOME/.celestia-app/
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

curl https://testnet-files.itrocket.net/celestia/snap_celestia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.celestia-app

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
