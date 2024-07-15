#!/bin/bash

# Ensure necessary tools are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null || ! command -v nc &> /dev/null; then
    echo "jq, curl, or nc (netcat) is not installed. Please install them and try again."
    exit 1
fi

# List of node IPs for querying
NODE_IPS=(
"https://celestia-testnet-rpc.itrocket.net/"
"https://celestia-testnet.rpc.kjnodes.com/"
"https://celestia-testnet-rpc.stake-town.com/"
"https://celestia.test.rpc.nodeshub.online/"
"https://celestia.rpc.testnets.services-ernventures.com/"
"https://celestia-rpc.0xcryptovestor.com"
"https://rpc.celestia.nodestake.top"
)

# Port for querying
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

# Initialize output file
OUTPUT_FILE="rpc_endpoints.txt"
LOG_FILE="rpc_check.log"

> $OUTPUT_FILE
> $LOG_FILE

# Function to check availability of a port on a given IP
check_rpc() {
    local ip=$1
    local port=$2
    echo "Проверка $ip:$port" | tee -a $LOG_FILE  # Log the process of checking
    if nc -zv -w 2 $ip $port 2>&1 | tee -a $LOG_FILE | grep -q "succeeded"; then
        echo "Доступен: $ip:$port" | tee -a $LOG_FILE
        echo "http://$ip:$port/" >> $OUTPUT_FILE
        return 0  # Успешное подключение, вернем 0
    else
        echo "Недоступен или превышен тайм-аут: $ip:$port" | tee -a $LOG_FILE
        return 1  # Не удалось подключиться, вернем 1
    fi
}

# Check each IP on each port
for ip in "${NODE_IPS[@]}"; do
    for port in "${PORTS[@]}"; do
        if check_rpc $ip $port; then
            break  # Если удалось подключиться, выходим из внутреннего цикла для этого IP
        fi
    done
done

# Display the results
echo "Список доступных RPC точек записан в файл $OUTPUT_FILE:" | tee -a $LOG_FILE
cat $OUTPUT_FILE | tee -a $LOG_FILE