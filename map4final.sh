#!/bin/bash

# Ensure necessary tools are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "jq or curl is not installed. Please install them and try again."
    exit 1
fi

# List of node IPs for querying
NODE_IPS=(
"57.129.38.74"
"162.55.94.173"
"185.38.19.202"
"78.46.65.144"
"37.27.119.173"
"162.55.245.144"
"217.160.102.31"
"138.201.82.234"
"95.217.225.107"
"65.21.233.188"
"178.23.126.58"
"5.9.118.55"
"65.109.23.114"
"209.159.154.142"
"185.252.220.89"
"85.10.196.25"
"186.3.232.252"
"88.198.12.182"
"149.102.149.157"
"14.140.57.92"
"199.127.60.37"
"89.187.156.100"
"141.94.138.48"
"164.68.111.29"
"65.108.124.43"
"185.130.226.110"
"206.189.143.243"
"156.67.110.37"
"5.9.237.194"
"15.235.183.138"
"139.45.205.58"
"65.108.12.253"
"65.109.103.176"
"65.109.25.113"
"211.219.19.78"
"67.217.62.242"
"65.109.93.124"
"85.204.122.199"
"138.201.63.38"
"65.109.16.220"
"178.211.139.77"
"148.113.8.171"
"164.152.163.148"
"72.46.84.33"
"20.250.38.245"
"194.62.97.34"
"95.217.200.98"
"49.12.168.110"
"88.218.224.73"
"46.4.30.231"
"62.169.25.91"
"144.76.152.250"
"65.109.88.22"
"65.108.235.238"
"89.58.36.209"
"139.84.218.54"
"185.144.99.223"
"158.220.87.136"
"65.108.226.183"
"65.21.237.228"
"65.109.117.151"
"65.109.54.91"
"178.23.126.32"
"178.63.116.125"
"15.235.218.151"
"65.108.192.123"
"37.27.52.123"
"46.4.80.48"
"65.108.108.54"
"46.4.5.45"
"85.10.201.238"
"148.251.177.108"
"89.117.49.68"
"65.108.73.124"
"43.157.50.9"
"162.250.127.226"
"148.113.17.55"
"89.117.52.159"
"74.208.16.201"
"65.108.69.151"
"86.48.31.105"
"65.109.55.18"
"135.181.113.225"
"95.214.55.76"
"88.99.61.173"
"185.16.36.147"
"135.181.210.171"
"38.242.239.185"
"54.151.206.207"
"13.229.218.33"
"49.12.150.42"
"88.99.219.120"
"65.21.136.101"
"5.9.10.222"
"45.143.198.5"
"136.243.55.115"
"5.9.147.138"
"136.243.94.113"
"95.217.113.247"
"85.207.33.76"
"3.66.8.141"
"149.50.101.203"
"54.82.200.23"
"54.38.112.219"
"207.229.99.15"
"65.21.139.160"
"89.58.51.28"
"65.109.66.190"
"125.253.92.7"
"65.108.141.109"
"195.3.220.54"
"190.2.137.108"
"51.158.60.9"
"67.209.54.140"
"207.148.65.211"
"103.184.192.238"
"62.171.148.127"
"64.176.57.63"
"165.22.31.221"
"103.219.170.87"
"185.165.170.88"
"129.232.222.18"
"65.109.98.239"
"43.202.67.62"
"199.247.20.188"
"65.21.12.42"
"2a01:4f9:3080:419e::5"
"13.127.104.31"
"85.10.201.238"
"185.209.178.177"
"82.223.31.166"
"158.247.233.222"
"193.34.213.77"
"116.202.237.79"
"174.138.180.246"
"18.139.78.193"
"34.32.212.204"
"85.10.196.25"
"23.111.187.102"
"185.16.36.147"
"89.58.36.209"
"185.130.226.110"
"67.217.62.242"
"185.165.170.88"
"3.231.68.59"
"62.138.24.120"
"65.109.93.58"
"109.66.190"
"141.94.73.39"
"41.58.125"
"104.219.237.146"
"136.175.9.193"
"38.58.183.3"
"51.159.215.215"
"104.243.40.149"
"93.159.130.38"
"142.132.202.87"
"156.67.110.37"
"62.138.24.120"
"94.130.35.35"
"95.216.223.149"
"91.121.55.152"
"64.227.18.169"
"45.143.198.5"
"136.243.176.86"
"57.129.1.77"
"116.202.217.20"
"199.247.20.188"
"65.108.73.124"
"3.66.8.141"
"199.127.60.37"
"65.109.16.220"
"65.109.88.22"
"65.109.98.239"
"149.102.149.157"
"85.10.201.238"
"89.58.51.28"
"65.109.54.91"
"65.109.66.190"
"65.109.117.151"
"65.109.126.24"
"65.21.237.228"
"65.21.233.188"
"136.243.94.113"
"158.220.87.136"
"116.202.217.20"
"209.159.154.142"
"95.214.55.76"
"85.204.122.199"
"65.109.30.163"
"136.243.55.115"
"67.217.62.242"
"103.219.171.47"
"89.187.156.100"
"199.127.60.37"
"207.229.99.15"
"135.181.113.225"
"141.94.138.48"
"3.231.68.59"
"162.55.65.137"
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
    "26657"
    "26656"
    "26658"
    "21657"
    "27657"
    "35657"
    "43567"
    "26698"
    "34657"
    "43657"
    "18657"
    "21657"
    "11657"
    "26658"
    "11656"
    "26679"
    "16007"
    "12056"
    "12057"
    "12059"
    "12060"
    "12045"
    "12065"
    "12066"
    "443"
    "40656"
    "36656"
    "35656"
    "26000"
    "26756"
    "56656"
    "10257"
    "26663"
    "46657"
    "26667"
    "28657"
    "30657"
    "36010"
    "36657"
    "5021"
    "26690"
    "26680"
    "20657"
    "23357"
    "57108"
    "26647"
)

# Fetch list of validators
echo "Fetching list of validators..."
validators=$(celestia-appd q staking validators --output json)

# Check if validators list was obtained
if [[ -z "$validators" ]]; then
    echo "Failed to get list of validators"
    exit 1
fi

# Initialize peers file
> peers.txt

# Get peer information from nodes
for NODE_IP in "${NODE_IPS[@]}"; do
    for PORT in "${PORTS[@]}"; do
        echo "Querying node $NODE_IP on port $PORT..."
        response=$(curl -s --max-time 10 --connect-timeout 5 http://$NODE_IP:$PORT/net_info)
        
        if [[ $? -ne 0 || -z "$response" ]]; then
            echo "Failed to get response from node $NODE_IP:$PORT."
            continue
        fi

        if echo "$response" | jq empty &> /dev/null; then
            echo "$response" | jq -r '.result.peers[] | .node_info.moniker + ";" + .remote_ip' >> peers.txt
            break  # Exit inner loop after getting first IP
        else
            echo "No valid data from node $NODE_IP:$PORT"
        fi
    done
done

# Parse JSON and match validators with IP addresses
echo "$validators" | jq -r '.validators[] | .description.moniker + ";" + .operator_address' > validators.txt

echo "List of validators and their IP addresses:" > result.txt
while read -r validator; do
    moniker=$(echo "$validator" | awk -F';' '{print $1}')
    address=$(echo "$validator" | awk -F';' '{print $2}')
    ip_list=$(grep "$moniker" peers.txt | awk -F';' '{print $2}' | sort | uniq | head -n 1)  # Get only the first IP
    if [[ -n "$ip_list" && "$ip_list" != "None" ]]; then
        echo "Validator: $moniker; Address: $address; IP: $ip_list" | tee -a result.txt
    else
        echo "Validator: $moniker; Address: $address; IP: None" | tee -a result.txt
    fi
done < validators.txt

echo "Results saved to result.txt"

# Get geolocation and hosting data for IP addresses
echo "Fetching geolocation and hosting data..."
> geo_results.txt  # Initialize file
while read -r line; do
    ip=$(echo "$line" | awk -F 'IP: ' '{print $2}')
    if [[ "$ip" != "None" ]]; then
        echo "Querying geolocation for IP: $ip..."
        geo_info=$(curl -s ipinfo.io/$ip)
        if [[ -n "$geo_info" ]]; then
            city=$(echo "$geo_info" | jq -r '.city // "Unknown"')
            region=$(echo "$geo_info" | jq -r '.region // "Unknown"')
            country=$(echo "$geo_info" | jq -r '.country // "Unknown"')
            loc=$(echo "$geo_info" | jq -r '.loc // "0.0,0.0"')
            org=$(echo "$geo_info" | jq -r '.org // "Unknown"')
            lat="${loc%%,*}"
            lng="${loc##*,}"
            echo "$line; $city; $region; $country; $lat; $lng; $org" >> geo_results.txt
        else
            echo "$line; Unknown; Unknown; Unknown; 0.0; 0.0; Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
        fi
    else
        echo "$line; Unknown; Unknown; Unknown; 0.0; 0.0; Unknown" >> geo_results.txt  # Ensure every line has the right number of fields
    fi
done < result.txt

echo "Geolocation and hosting data saved to geo_results.txt"

# Transition to Python script for map display
python3 plot_map.py
