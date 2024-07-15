#!/bin/bash

# Задаем список возможных RPC портов
RPC_PORTS=(26657 26658 26659 26660)

# Файл для записи результатов
OUTPUT_FILE="rpc_endpoints.txt"

# Очищаем файл перед записью
> $OUTPUT_FILE

# Выполняем запрос к локальному RPC серверу и извлекаем адреса узлов
PEER_IPS=$(curl -s http://localhost:26657/net_info | jq -r '.result.peers[].remote_ip')

# Записываем каждый IP на каждом из возможных портов
for ip in $PEER_IPS; do
  for port in "${RPC_PORTS[@]}"; do
    echo "http://$ip:$port/" >> $OUTPUT_FILE
  done
done

# Проверяем содержимое файла
echo "Список доступных RPC точек записан в файл $OUTPUT_FILE:"
cat $OUTPUT_FILE