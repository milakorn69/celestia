#!/bin/bash

# Получаем список валидаторов через API
validators=$(curl -s https://celestia.api.testnets.services-ernventures.com/cosmos/staking/v1beta1/validators | jq -r '.validators[] | .description.moniker + " " + .operator_address')

# Проверка, удалось ли получить список валидаторов
if [[ -z "$validators" ]]; then
    echo "Не удалось получить список валидаторов"
    exit 1
fi

# Инициализация файла для пиров
> peers.txt

# Получаем информацию о пирах через RPC
response=$(curl -s https://celestia.rpc.testnets.services-ernventures.com/net_info)

# Проверка, удалось ли получить ответ от RPC
if [[ -z "$response" ]]; then
    echo "Не удалось получить данные о пирах"
    exit 1
fi

# Парсим ответ и сохраняем информацию о пирах
echo "$response" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' > peers.txt

# Проверка содержимого файла peers.txt
echo "Содержимое файла peers.txt:"
cat peers.txt

# Сопоставление валидаторов и IP-адресов
echo "Список валидаторов и их IP-адресов:"
echo "$validators" | while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq)
    if [[ -n "$ip_list" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip_list"
    else
        echo "Для валидатора $moniker не найдено IP-адресов."
    fi
done