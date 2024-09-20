#!/bin/bash

# Обновление системы и установка необходимых пакетов
sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make gcc lz4 -y

# Переменные окружения для Celestia
CELESTIA_PORT=26
WALLET='ERN'
MONIKER='ERN'
CHAIN_ID='mocha-4'

echo "export WALLET='${WALLET}'" >> $HOME/.bash_profile
echo "export MONIKER='${MONIKER}'" >> $HOME/.bash_profile
echo "export CHAIN_ID='${CHAIN_ID}'" >> $HOME/.bash_profile
echo "export CELESTIA_PORT='${CELESTIA_PORT}'" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Установка последней версии Go
if ! [ -x "$(command -v go)" ]; then
    GO_VERSION="1.21.1"
    wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
    rm "go$GO_VERSION.linux-amd64.tar.gz"
    echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    source ~/.bash_profile
fi

# Проверка версии Go
go version

# Скачивание и установка Celestia
cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
APP_VERSION=v2.1.2
git checkout tags/$APP_VERSION -b $APP_VERSION

# Исправление модуля cmp в go.mod
go mod edit -replace cmp=github.com/google/go-cmp@v0.5.8

# Очистка зависимостей и обновление go.mod
go mod tidy

# Сборка и установка Celestia
make build
make install

# Настройка Celestia
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git

# Конфигурация celestia-appd
celestia-appd config node tcp://localhost:${CELESTIA_PORT}657
celestia-appd config keyring-backend os
celestia-appd config chain-id $CHAIN_ID
celestia-appd init $MONIKER --chain-id $CHAIN_ID

# Загрузка genesis и addrbook
wget -O $HOME/.celestia-app/config/genesis.json https://testnets.services-ernventures.com/celestia/genesis.json
wget -O $HOME/.celestia-app/config/addrbook.json https://testnets.services-ernventures.com/celestia/addrbook.json

# Настройка SEEDS и PEERS
SEEDS="5d0bf034d6e6a8b5ee31a2f42f753f1107b3a00e@celestia-testnet-seed.itrocket.net:11656"
PEERS="77f8a816610d521cecb4c62f834891e1a6257b09@65.108.207.143:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml

# Настройка портов в конфигурации
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CELESTIA_PORT}317\"%;
s%^address = \":8080\"%address = \":${CELESTIA_PORT}080\"%;
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CELESTIA_PORT}090\"%; 
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CELESTIA_PORT}091\"%; 
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CELESTIA_PORT}545\"%; 
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CELESTIA_PORT}546\"%" $HOME/.celestia-app/config/app.toml

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CELESTIA_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CELESTIA_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CELESTIA_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CELESTIA_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CELESTIA_PORT}660\"%" $HOME/.celestia-app/config/config.toml

# Применение настроек для pruning
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.celestia-app/config/app.toml

# Настройка внешнего адреса
EXTERNAL_ADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external-address = \"\"/external-address = \"$EXTERNAL_ADDRESS:26656\"/" $HOME/.celestia-app/config/config.toml

# Установка минимальных цен на газ и включение Prometheus
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.002utia\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.celestia-app/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.celestia-app/config/config.toml

# Сброс состояния Tendermint
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app

# Создание и установка systemd-сервиса для celestia-appd
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

# Установка снапшота
cd $HOME
rm -rf ~/.celestia-app/data
mkdir -p ~/.celestia-app/data
wget -O snap_celestia.tar.lz4 https://testnets.services-ernventures.com/celestia/snap_celestia-prun.tar.lz4
lz4 -dc snap_celestia.tar.lz4 | tar -xf - -C $HOME/.celestia-app/data

# Перезапуск systemd-сервиса
sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f