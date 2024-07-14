#!/bin/bash

# Проверка, установлен ли jq и curl
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Установите их и попробуйте снова."
    exit 1
fi

# Список IP-адресов узлов для опроса
NODE_IPS=(
"104.219.237.146:26667"
"37.27.109.215:26657"
"136.175.9.193:26657"
"85.10.196.25:26657"
"209.159.154.142:26657"
"104.243.40.149:26657"
"65.109.54.91:21657"
"158.220.87.136:26657"
"38.58.183.3:26657"
"51.159.215.215:26657"
"65.108.142.147:27657"
"138.201.82.234:26657"
"38.242.234.180:26657"
"93.159.130.38:35657"
"141.94.73.39:43657"
"142.132.202.87:26698"
"95.217.225.107:26657"
"65.109.16.220:26657"
"15.235.218.151:26667"
"88.198.12.182:26657"
"https://celestia-testnet-rpc.itrocket.net"
"https://celestia-testnet.rpc.kjnodes.com"
"https://celestia-testnet-rpc.stake-town.com"
"162.19.19.41:26657"
"5.9.10.222:26657"
"64.176.57.63:26657"
"141.95.35.218:26657"
"57.129.1.77:26657"
"37.27.119.173:26657"
"116.202.217.20:34657"
"217.160.102.31:26647"
"62.138.24.120:26657"
"88.99.219.120:43657"
"94.130.35.35:18657"
"95.216.223.149:26657"
"91.121.55.152:26657"
"125.253.92.7:26657"
"64.227.18.169:26657"
"195.14.6.178:26657"
"45.143.198.5:26657"
"95.217.200.98:21657"
"136.243.176.86:26657"
"141.94.135.203:26657"
"https://rpc-t.celestia.nodestake.top"
"162.55.65.137:11657"
)

# Порт для опроса
PORTS=(
"26667"
"26657"
"21657"
"27657"
"35657"
"43657"
"26698"
"34657"
"26647"
"18657"
"11657"
"443"
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
            break  # Выходим из внутреннего цикла после получения первого IP
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
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq | head -n 1)  # Получаем только первый IP
    if [[ -n "$ip_list" ]]; then
        echo "Валидатор: $moniker, Адрес: $address, IP: $ip_list" | tee -a result.txt
    else
        echo "Для валидатора $moniker не найдено IP-адресов." | tee -a result.txt
    fi
done < validators.txt

echo "Результаты сохранены в файл result.txt"

# Получение геолокационных данных для IP-адресов
echo "Получение геолокационных данных..."
> geo_results.txt  # Инициализация файла
while read -r line; do
    ip=$(echo "$line" | awk '{print $NF}')
    echo "Запрашиваем геолокацию для IP: $ip..."
    geo_info=$(curl -s ipinfo.io/$ip)
    echo "Ответ от ipinfo.io: $geo_info"  # Выводим ответ для отладки
    if [[ -n "$geo_info" ]]; then
        city=$(echo "$geo_info" | jq -r '.city')
        region=$(echo "$geo_info" | jq -r '.region')
        country=$(echo "$geo_info" | jq -r '.country')
        loc=$(echo "$geo_info" | jq -r '.loc')
        if [[ -n "$city" && -n "$region" && -n "$country" && -n "$loc" ]]; then
            echo "$line, $city, $region, $country, $loc" >> geo_results.txt
        else
            echo "$line, , , , " >> geo_results.txt
        fi
    else
        echo "$line, , , , " >> geo_results.txt
    fi
done < result.txt

echo "Геолокационные данные сохранены в файл geo_results.txt"

# Переход к Python скрипту для отображения на карте
python3 plot_map.py
