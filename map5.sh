#!/bin/bash

# Убедитесь, что необходимые инструменты установлены
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq или curl не установлены. Пожалуйста, установите их и повторите попытку."
    exit 1
fi

# Список IP-адресов узлов для запросов
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
"162.55.65.137"
"https://celestia-testnet-rpc.itrocket.net/"
"https://celestia-testnet.rpc.kjnodes.com/"
"https://celestia-testnet-rpc.stake-town.com/"
"https://celestia.test.rpc.nodeshub.online/"
"https://celestia.rpc.testnets.services-ernventures.com/"
"https://celestia-rpc.0xcryptovestor.com"
"https://rpc.celestia.nodestake.top"
)

# Порты для запросов
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

# Получение списка валидаторов
echo "Получение списка валидаторов..."
validators=$(celestia-appd q staking validators --output json)

# Проверка, удалось ли получить список валидаторов
if [[ -z "$validators" ]]; then
    echo "Не удалось получить список валидаторов"
    exit 1
fi

# Инициализация файла с пирами
> peers.txt

# Функция для проверки доступности порта на данном IP
check_rpc() {
    local ip=$1
    local port=$2
    echo "Проверка $ip:$port"  # Лог процесса проверки
    if curl -s --max-time 2 --connect-timeout 2 "http://$ip:$port/net_info" 2>&1 | grep -q "result"; then
        echo "Доступен: $ip:$port"
        return 0  # Успешное подключение, возвращаем 0
    else
        echo "Недоступен или превышен тайм-аут: $ip:$port"
        return 1  # Не удалось подключиться, возвращаем 1
    fi
}

# Получение информации о пирах с узлов
for NODE_IP in "${NODE_IPS[@]}"; do
    for PORT in "${PORTS[@]}"; do
        echo "Запрос узла $NODE_IP на порту $PORT..."
        if check_rpc $NODE_IP $PORT; then
            response=$(curl -s "http://$NODE_IP:$PORT/net_info")
            if [[ $? -ne 0 || -z "$response" ]]; then
                echo "Не удалось получить ответ от узла $NODE_IP:$PORT."
                continue
            fi

            if echo "$response" | jq empty &> /dev/null; then
                echo "$response" | jq -r '.result.peers[] | .node_info.moniker + ";" + .remote_ip' >> peers.txt
                break  # Выходим из внутреннего цикла после получения первого IP
            else
                echo "Нет действительных данных от узла $NODE_IP:$PORT"
            fi
        fi
    done
done

# Разбор JSON и сопоставление валидаторов с IP-адресами
echo "$validators" | jq -r '.validators[] | .description.moniker + ";" + .operator_address' > validators.txt

echo "Список валидаторов и их IP-адреса:" > result.txt
> all_ips.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk -F';' '{print $1}')
    address=$(echo "$validator" | awk -F';' '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk -F';' '{print $2}' | sort | uniq | head -n 1)  # Получаем только первый IP
    if [[ -n "$ip_list" && "$ip_list" != "None" ]]; then
        echo "$moniker;$address;$ip_list" | tee -a result.txt
        echo "$moniker;$ip_list" >> all_ips.txt
    else
        echo "$moniker;$address;None" | tee -a result.txt
    fi
done < validators.txt

echo "Результаты сохранены в result.txt"
echo "Все IP сохранены в all_ips.txt"

# Получение данных о геолокации и хостинге для IP-адресов
echo "Получение данных о геолокации и хостинге..."
> geo_results.txt  # Инициализация файла
while read -r line; do
    moniker=$(echo "$line" | awk -F';' '{print $1}')
    ip=$(echo "$line" | awk -F';' '{print $2}')
    if [[ "$ip" != "None" ]]; then
        echo "Запрос геолокации для IP: $ip..."
        geo_info=$(curl -s ipinfo.io/$ip)
        if [[ -n "$geo_info" ]]; then
            city=$(echo "$geo_info" | jq -r '.city // "Unknown"')
            region=$(echo "$geo_info" | jq -r '.region // "Unknown"')
            country=$(echo "$geo_info" | jq -r '.country // "Unknown"')
            loc=$(echo "$geo_info" | jq -r '.loc // "0.0,0.0"')
            org=$(echo "$geo_info" | jq -r '.org // "Unknown"')
            lat="${loc%%,*}"
            lng="${loc##*,}"
            echo "$moniker;$ip;$city;$region;$country;$lat;$lng;$org" >> geo_results.txt
        else
            echo "$moniker;$ip;Unknown;Unknown;Unknown;0.0;0.0;Unknown" >> geo_results.txt  # Убеждаемся, что каждая строка имеет правильное количество полей
        fi
    else
        echo "$moniker;$ip;Unknown;Unknown;Unknown;0.0;0.0;Unknown" >> geo_results.txt  # Убеждаемся, что каждая строка имеет правильное количество полей
    fi
done < all_ips.txt

echo "Данные о геолокации и хостинге сохранены в geo_results.txt"

# Создание Python скрипта plot_map.py
echo 'import requests
import pandas as pd
from geopy.geocoders import Nominatim
import folium
from folium.plugins import MarkerCluster

def get_geo_info(ip):
    try:
        response = requests.get(f"http://ipinfo.io/{ip}/json")
        if response.status_code == 200:
            return response.json()
        else:
            return None
    except Exception as e:
        print(f"Error fetching data from ipinfo.io: {e}")
        return None

def get_coordinates_via_geopy(city, country):
    geolocator = Nominatim(user_agent="geoapiExercises")
    try:
        location = geolocator.geocode(f"{city}, {country}")
        if location:
            return location.latitude, location.longitude
        else:
            return None, None
    except Exception as e:
        print(f"Error fetching coordinates via geopy: {e}")
        return None, None

# Чтение файла geo_results.txt
with open("geo_results.txt", "r") as file:
    lines = file.readlines()

output_data = []

for line in lines:
    parts = line.strip().split(";")
    if len(parts) == 8:
        validator, ip, city, region, country, lat, lng,