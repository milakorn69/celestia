#!/bin/bash

# Check if jq and curl are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq or curl is not installed. Please install them and try again."
    exit 1
fi

# List of node IPs for querying
NODE_IPS=(
"78.46.65.144"
"72.46.84.33"
"193.34.213.190"
"195.3.221.146"
"70.165.57.67"
"65.21.227.52"
"65.108.142.147"
"https://celestia-testnet-rpc.itrocket.net/"
"https://celestia-testnet.rpc.kjnodes.com/"
"https://celestia-testnet-rpc.stake-town.com/"
"https://celestia.test.rpc.nodeshub.online/"
"https://celestia.rpc.testnets.services-ernventures.com/"
)

# Port for querying
PORTS=(
    "26657"
    "443"
)

# Get list of validators
echo "Fetching list of validators..."
validators=$(celestia-appd q staking validators --output json)

# Check if validators list was obtained
if [[ -z "$validators" ]]; then
    echo "Failed to get list of validators"
    exit 1
fi

echo "Validators list obtained. Validator data:"
echo "$validators" | jq .

# Initialize peers file
> peers.txt

# Get peer information from several nodes and ports
for NODE_IP in "${NODE_IPS[@]}"; do
    for PORT in "${PORTS[@]}"; do
        echo "Querying node $NODE_IP on port $PORT..."
        response=$(curl -s --max-time 10 --connect-timeout 5 http://$NODE_IP:$PORT/net_info)
        
        # Check response status
        if [[ $? -ne 0 ]]; then
            echo "Failed to get response from node $NODE_IP:$PORT within the specified time."
            continue
        fi
        
        # Check for empty response
        if [[ -z "$response" ]]; then
            echo "Empty response from node $NODE_IP:$PORT."
            continue
        fi

        # Output response for debugging
        echo "Response from node $NODE_IP:$PORT:"
        echo "$response" | jq .
        
        if echo "$response" | jq empty &> /dev/null; then
            echo "$response" | jq -r '.result.peers[] | .node_info.moniker + " " + .remote_ip' >> peers.txt
            break  # Exit inner loop after getting first IP
        else
            echo "No data from node $NODE_IP:$PORT"
        fi
    done
done

# Check contents of peers.txt
echo "Contents of peers.txt:"
cat peers.txt

# Parse JSON and match validators with IP addresses
echo "$validators" | jq -r '.validators[] | .description.moniker + " " + .operator_address' > validators.txt

echo "List of validators and their IP addresses:" > result.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk '{print $1}')
    address=$(echo "$validator" | awk '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk '{print $2}' | sort | uniq | head -n 1)  # Get only the first IP
    if [[ -n "$ip_list" ]]; then
        echo "Validator: $moniker, Address: $address, IP: $ip_list" | tee -a result.txt
    else
        echo "Validator: $moniker, Address: $address, IP: None" | tee -a result.txt
    fi
done < validators.txt

echo "Results saved to result.txt"

# Get geolocation and hosting data for IP addresses
echo "Fetching geolocation and hosting data..."
> geo_results.txt  # Initialize file
while read -r line; do
    ip=$(echo "$line" | awk '{print $NF}')
    if [[ "$ip" != "None" ]]; then
        echo "Querying geolocation for IP: $ip..."
        geo_info=$(curl -s ipinfo.io/$ip)
        echo "Response from ipinfo.io: $geo_info"  # Output response for debugging
        if [[ -n "$geo_info" ]]; then
            city=$(echo "$geo_info" | jq -r '.city // "Unknown"')
            region=$(echo "$geo_info" | jq -r '.region // "Unknown"')
            country=$(echo "$geo_info" | jq -r '.country // "Unknown"')
            loc=$(echo "$geo_info" | jq -r '.loc // "0.0,0.0"')
            org=$(echo "$geo_info" | jq -r '.org // "Unknown"')
            lat="${loc%%,*}"
            lng="${loc##*,}"
            echo "$line, $city, $region, $country, $lat, $lng, $org" >> geo_results.txt
        else
            echo "$line, Unknown, Unknown, Unknown, 0.0, 0.0, Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
        fi
    else
        echo "$line, Unknown, Unknown, Unknown, 0.0, 0.0, Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
    fi
done < result.txt

echo "Geolocation and hosting data saved to geo_results.txt"

# Transition to Python script for map display
python3 plot_map.py
