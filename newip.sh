#!/bin/bash

# Список IP-адресов узлов для опроса
NODE_IPS=(
    "78.46.65.144" 
    "78.46.65.144"
    "136.175.9.193" 
    "135.181.5.232" 
    "78.46.65.144" 
    "148.113.8.171" 
    "213.239.201.202" 
    "136.175.9.193" 
    "57.128.63.22" 
    "135.181.5.232" 
    "3.15.1.122" 
    "94.130.35.35" 
    "89.58.36.209" 
    "142.132.202.87"
)

# Список портов для опроса
PORTS=(
    "26657"
    "26656"
    "26658"
)

# Получаем список валидаторов
validators=$(celestia-appd q staking validators --output json)

# Проверка, удалось ли получить список валидаторов
if [[ -z "$validators" ]]; then
    echo "Не удалось получить список валидаторов"
    exit 1
fi

# Инициализация файла для пиров
> peers.txt

# Получаем информацию о пирах с нескольких узлов и портов
for NODE_IP in "${NODE_IPS[@]}"; do
    for PORT in "${PORTS[@]}"; do
        peers=$(curl -s http://$NODE_IP:$PORT/net_info)
        if [[ -n "$peers" ]]; then
            echo "$peers" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
        fi
    done
done

# Парсинг JSON и сопоставление валидаторов и IP-адресов
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "Список валидаторов и их IP-адресов:"
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq)
    if [[ -n "$ip_list" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip_list"
    fi
done < validators.txt