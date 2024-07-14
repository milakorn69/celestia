#!/bin/bash

# Проверка, установлен ли jq и curl
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Установите их и попробуйте снова."
    exit 1
fi

# Список IP-адресов узлов для опроса
NODE_IPS=(
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
"93.159.130.38"
"141.94.73.39"
"142.132.202.87"
"95.217.225.107"
"65.109.16.220"
"15.235.218.151"
"88.198.12.182"
"https://celestia-testnet-rpc.itrocket.net"
"https://celestia-testnet.rpc.kjnodes.com"
"https://celestia-testnet-rpc.stake-town.com"
"162.19.19.41"
"5.9.10.222"
"64.176.57.63"
"141.95.35.218"
"57.129.1.77"
"37.27.119.173"
"116.202.217.20"
"217.160.102.31"
"62.138.24.120"
"88.99.219.120"
"94.130.35.35"
"95.216.223.149"
"91.121.55.152"
"125.253.92.7"
"64.227.18.169"
"195.14.6.178"
"45.143.198.5"
"95.217.200.98"
"136.243.176.86"
"141.94.135.203"
"https://rpc-t.celestia.nodestake.top"
"162.55.65.137"
)

# Порт для опроса
PORTS=(
"26667"
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
        echo "Валидатор: $moniker, Адрес: $address, IP: None" | tee -a result.txt
    fi
done < validators.txt

echo "Результаты сохранены в файл result.txt"

# Получение геолокационных данных для IP-адресов
echo "Получение геолокационных данных..."
> geo_results.txt  # Инициализация файла
while read -r line; do
    ip=$(echo "$line" | awk '{print $NF}')
    if [[ "$ip" != "None" ]]; then
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
    else
        echo "$line, , , , " >> geo_results.txt
    fi
done < result.txt

echo "Геолокационные данные сохранены в файл geo_results.txt"

# Переход к Python скрипту для отображения на карте
python3 plot_map.py
