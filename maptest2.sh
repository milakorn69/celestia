#!/bin/bash

# Проверка, установлен ли jq и curl
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Установите их и попробуйте снова."
    exit 1
fi

# Список IP-адресов узлов для опроса
NODE_IPS=(
"78.46.65.144"
"65.21.227.52"
"65.108.142.147"
"https://celestia-testnet-rpc.itrocket.net/"
"https://celestia-testnet.rpc.kjnodes.com/"
"https://celestia-testnet-rpc.stake-town.com/"
"https://celestia.test.rpc.nodeshub.online/"
"https://celestia.rpc.testnets.services-ernventures.com/"
)

# Порт для опроса
PORTS=(
    "26657"
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
