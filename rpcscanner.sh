#!/bin/bash

# Задаем список возможных RPC портов
RPC_PORTS=(26657 26658 26659 26660)

# Файл для записи результатов
OUTPUT_FILE="rpc_endpoints.txt"

# Очищаем файл перед записью
> $OUTPUT_FILE

# Функция для проверки доступности RPC на заданном порту
check_rpc() {
  local ip=$1
  local port=$2
  if curl -s --head "http://$ip:$port/" | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
    echo "http://$ip:$port/" >> $OUTPUT_FILE
  fi
}

# Выполняем запрос к локальному RPC серверу и извлекаем адреса узлов
PEER_IPS=$(curl -s http://localhost:26657/net_info | jq -r '.result.peers[].remote_ip')

# Проверяем каждый IP на каждом из возможных портов
for ip in $PEER_IPS; do
  for port in "${RPC_PORTS[@]}"; do
    check_rpc $ip $port
  done
done

# Проверяем содержимое файла
echo "Список доступных RPC точек записан в файл $OUTPUT_FILE:"
cat $OUTPUT_FILE