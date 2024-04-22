#!/bin/bash
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.13.4 
make build 
systemctl daemon-reload
systemctl restart celestia-bridge && journalctl -u celestia-bridge -f -o cat
