# Celestia
<div>
<h1 align="left" style="display: flex;"> Celestia node Setup for Mocha-4 Testnet and Celestia mainnet</h1>
<img src="https://avatars.githubusercontent.com/u/54859940?s=200&v=4"  style="float: right;" width="100" height="100"></img>
</div>

Official documentation:
>- [Validator setup instructions](https://docs.celestia.org/nodes/consensus-node)
# install test validator
~~~bash
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installvalidatortest.sh)
~~~
# install main validator
~~~bash
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installvalidatormain.sh)
~~~
# install full test node
~~~bash
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installfulltest.sh)
~~~
# install full main node
~~~bash
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installfullmain.sh)
~~~
# install test bridge
~~~bash 
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installbridgetest.sh)
~~~
# install main bridge
~~~bash 
source <(curl -s https://raw.githubusercontent.com/ERNcrypto/celestia/main/installbridgemain.sh)
~~~

### Firewall security
Set the default to allow outgoing connections, deny all incoming, allow ssh and node p2p port
  ~~~bash
  sudo ufw enable 
  sudo ufw default allow outgoing 
  sudo ufw default deny incoming 
  sudo ufw allow ssh/tcp 
  sudo ufw allow 26658,2121/tcp 
  sudo ufw allow 2121/udp 
  ~~~
