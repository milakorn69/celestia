#!/bin/bash

# Проверка, установлен ли jq и curl
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Установите их и попробуйте снова."
    exit 1
fi

# Список IP-адресов узлов для опроса
NODE_IPS=(
    "136.243.176.86"
)

# Порт для опроса
RPC_PORT="26657"

# Получаем список валидаторов
echo "Получаем список валидаторов..."
validators=$(celestia-appd q staking validators --output json)

# Проверка, удалось ли получить список валидаторов
if [[ -z "$validators" ]]; then
    echo "Не удалось получить список валидаторов"
    exit 1
fi

echo "Список валидаторов получен. Данные валидаторов:"
echo "$validators" | jq .

# Инициализация файла для пиров
> peers.txt

# Получаем информацию о пирах с нескольких узлов и портов
for NODE_IP in "${NODE_IPS[@]}"; do
    echo "Запрашиваем информацию у узла $NODE_IP на порту $RPC_PORT..."
    response=$(curl -s http://$NODE_IP:$RPC_PORT/net_info)
    
    # Выводим ответ для отладки
    echo "Ответ от узла:"
    echo "$response" | jq .
    
    if echo "$response" | jq empty &> /dev/null; then
        echo "$response" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
    else
        echo "Нет данных от узла $NODE_IP:$RPC_PORT"
    fi
done

# Проверка содержимого файла peers.txt
echo "Содержимое файла peers.txt:"
cat peers.txt

# Парсинг JSON и сопоставление валидаторов и IP-адресов
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "Список валидаторов и их IP-адресов:"
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq)
    if [[ -n "$ip_list" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip_list"
    else
        echo "Для валидатора $moniker не найдено IP-адресов."
    fi
done < validators.txt