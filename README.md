# Celestia
# install node
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/install.sh)
# install full node
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installfull.sh)
# install bridge
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installbridge.sh)

# sudo ufw enable
#  sudo ufw default allow outgoing 
#  sudo ufw default deny incoming 
#  sudo ufw allow ssh/tcp 
#  sudo ufw allow 29658,2121,/tcp
#  sudo ufw allow 2121/udp
