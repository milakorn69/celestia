#!/bin/bash
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v2.2.0-mocha
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install
sudo systemctl restart celestia-appd && sudo journalctl -u celestia-appd -f
