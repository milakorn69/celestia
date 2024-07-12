#!/bin/bash

# Замените <IP-адрес-ноды> и <Порт-RPC> на реальные значения нескольких узлов
NODE_IPS=("78.46.65.144" "78.46.65.144" "78.46.65.144" "148.113.8.171" "94.130.35.35" "142.132.202.87" "136.243.176.86")
RPC_PORT="26657"

# Получаем список валидаторов
validators=$(celestia-appd q staking validators --output json)

# Проверка, удалось ли получить список валидаторов
if [[ -z "$validators" ]]; then
    echo "Не удалось получить список валидаторов"
    exit 1
fi

# Инициализация файла для пиров
> peers.txt

# Получаем информацию о пирах с нескольких узлов
for NODE_IP in "${NODE_IPS[@]}"; do
    peers=$(curl -s http://$NODE_IP:$RPC_PORT/net_info)
    echo "$peers" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
done

# Парсинг JSON и сопоставление валидаторов и IP-адресов
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "Список валидаторов и их IP-адресов:"
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip=$(grep "$moniker" peers.txt | awk '{print $2}')
    if [[ -n "$ip" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip"
    fi
done < validators.txt