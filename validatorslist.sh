#!/bin/bash

# Получаем список валидаторов
validators=$(celestia-appd q staking validators --output json)

# Получаем информацию о пирах
peers=$(curl -s http://<IP-адрес-ноды>:<Порт-RPC>/net_info)

# Парсинг JSON и сопоставление валидаторов и IP-адресов
echo $validators | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt
echo $peers | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' > peers.txt

echo "Список валидаторов и их IP-адресов:"
while read -r validator; do
    moniker=$(echo $validator | awk '{print $1}')
    address=$(echo $validator | awk '{print $2}')
    ip=$(grep $moniker peers.txt | awk '{print $2}')
    echo "Валидатор: $moniker, Адрес: $address, IP: $ip"
done < validators.txt