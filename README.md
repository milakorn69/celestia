# Celestia
# install test validator
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installvalidatortest.sh)
# install main validator
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installvalidatormain.sh)
# install full test node
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installfulltest.sh)
# install full main node
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installfullmain.sh)
# install test bridge 
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installbridgetest.sh)
# install main bridge 
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installbridgemain.sh)

# sudo ufw enable
#sudo ufw default allow outgoing 
#  sudo ufw default deny incoming 
#  sudo ufw allow ssh/tcp 
#  sudo ufw allow 26658,2121/tcp
#  sudo ufw allow 2121/udp
