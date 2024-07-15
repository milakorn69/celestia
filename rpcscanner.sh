#!/bin/bash

# Задаем список возможных RPC портов
RPC_PORTS=(26657 26658 26659 26660 26667 21657 27657 35657 43657 26698 34657 26647 18657 11657 443)

# Файл для записи результатов
OUTPUT_FILE="rpc_endpoints.txt"
LOG_FILE="rpc_check.log"

# Очищаем файлы перед записью
> $OUTPUT_FILE
> $LOG_FILE

# Функция для проверки доступности порта на заданном IP
check_rpc() {
  local ip=$1
  local port=$2
  echo "Проверка $ip:$port" | tee -a $LOG_FILE  # Логирование процесса проверки
  if nc -z -w 10 $ip $port 2>>$LOG_FILE; then
    echo "Доступен: $ip:$port" | tee -a $LOG_FILE
    echo "http://$ip:$port/" >> $OUTPUT_FILE
  else
    echo "Недоступен или превышен тайм-аут: $ip:$port" | tee -a $LOG_FILE
  fi
}

# Выполняем запрос к локальному RPC серверу и извлекаем адреса узлов
echo "Получение списка узлов..." | tee -a $LOG_FILE
PEER_IPS=$(curl -s http://localhost:26657/net_info | jq -r '.result.peers[].remote_ip' 2>>$LOG_FILE)
echo "Список узлов получен: $PEER_IPS" | tee -a $LOG_FILE

# Проверяем каждый IP на каждом из возможных портов
for ip in $PEER_IPS; do
  for port in "${RPC_PORTS[@]}"; do
    check_rpc $ip $port
  done
done

# Проверяем содержимое файла
echo "Список доступных RPC точек записан в файл $OUTPUT_FILE:" | tee -a $LOG_FILE
cat $OUTPUT_FILE | tee -a $LOG_FILE