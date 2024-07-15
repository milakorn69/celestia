#!/bin/bash

# Задаем RPC порт
RPC_PORT=26657

# Выполняем запрос к локальному RPC серверу и извлекаем адреса узлов, преобразуя их в URL
curl -s http://localhost:$RPC_PORT/net_info | jq -r --arg port "$RPC_PORT" '.result.peers[] | "http://\(.remote_ip):\($port)/"' > rpc_endpoints.txt

# Проверяем содержимое файла
echo "Список доступных RPC точек записан в файл rpc_endpoints.txt:"
cat rpc_endpoints.txt