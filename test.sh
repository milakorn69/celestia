#!/bin/bash

# Проверка, установлен ли jq и curl
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Установите их и попробуйте снова."
    exit 1
fi

# Список IP-адресов узлов для опроса
NODE_IPS=(
"78.46.65.144"
"148.113.8.171"
"94.130.35.35"
"142.132.202.87"
"136.243.176.86"
"141.94.138.48"
"195.14.6.178"
"164.152.163.148"
"65.108.12.253"
"177.54.156.69"
"65.21.136.101"
"205.209.125.70"
"65.21.233.188"
"211.219.19.78"
"93.190.143.6"
"141.94.135.203"
"217.160.102.31"
"13.212.141.100"
"162.250.127.226"
"31.7.196.17"
"141.95.35.218"
"72.46.84.33"
"185.144.99.223"
"88.218.224.72"
"91.121.55.152"
"104.219.237.146"
"37.27.109.215"
"136.175.9.193"
"85.10.196.25"
"209.159.154.142"
"104.243.40.149"
"65.109.54.91"
"158.220.87.136"
"38.58.183.3"
"51.159.215.215"
"65.108.142.147"
"138.201.82.234"
"38.242.234.180"
"54.36.118.32"
"93.159.130.38"
"141.94.73.39"
"95.217.225.107"
"65.109.16.220"
"15.235.218.151"
"88.198.12.182"
"celestia-testnet-rpc.itrocket.net"
"celestia-testnet.rpc.kjnodes.com"
"celestia-testnet-rpc.stake-town.com"
"celestia.test.rpc.nodeshub.online"
)

# Порт для опроса
PORTS=(
    "26657"
    "26656"
    "26658"
    "21657"
    "27657"
    "35657"
    "43567"
    "26698"
    "34657"
    "43657"
    "18657"
    "21657"
    "11657"
    "26658"
    "11656"
    "26679"
    "16007"
)

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
    for PORT in "${PORTS[@]}"; do
        echo "Запрашиваем информацию у узла $NODE_IP на порту $PORT..."
        response=$(curl -s --max-time 10 --connect-timeout 5 http://$NODE_IP:$PORT/net_info)
        
        # Проверка статуса ответа
        if [[ $? -ne 0 ]]; then
            echo "Не удалось получить ответ от узла $NODE_IP:$PORT в течение заданного времени."
            continue
        fi
        
        # Проверка на пустой ответ
        if [[ -z "$response" ]]; then
            echo "Пустой ответ от узла $NODE_IP:$PORT."
            continue
        fi

        # Выводим ответ для отладки
        echo "Ответ от узла $NODE_IP:$PORT:"
        echo "$response" | jq .
        
        if echo "$response" | jq empty &> /dev/null; then
            echo "$response" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
        else
            echo "Нет данных от узла $NODE_IP:$PORT"
        fi
    done
done

# Проверка содержимого файла peers.txt
echo "Содержимое файла peers.txt:"
cat peers.txt

# Парсинг JSON и сопоставление валидаторов и IP-адресов
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "Список валидаторов и их IP-адресов:" > result.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq)
    if [[ -n "$ip_list" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip_list" | tee -a result.txt
    else
        echo "Для валидатора $moniker не найдено IP-адресов." | tee -a result.txt
    fi
done < validators.txt

echo "Результаты сохранены в файл result.txt"