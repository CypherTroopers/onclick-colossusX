#!/usr/bin/env bash
set -euo pipefail

echo "==> Update system"
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

echo "==> Install packages"
sudo apt-get install -y curl git wget texinfo nodejs npm pcscd

echo "==> Install latest Node.js using n"
sudo npm install -g n
sudo n stable
sudo apt purge -y nodejs npm
sudo apt autoremove -y

export PATH=/usr/local/bin:$PATH
hash -r

echo "==> Install PM2"
sudo /usr/local/bin/npm install -g pm2

echo "==> Clone Cypherium repo"
if [ ! -d cypher ]; then
  git clone https://github.com/CypherTroopers/cypher.git
fi

cd cypher

echo "==> Init chaindbname"
./build/bin/cypher --datadir chaindbname init ./genesistest.json

echo "==> Create start-cypher.sh"
cat <<'EOS' > start-cypher.sh
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

./build/bin/cypher \
  --verbosity 4 \
  --rnetport 7200 \
  --syncmode full \
  --nat extip:$(curl -4 -s ifconfig.io) \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port 9251 \
  --ws.origins "*" \
  --metrics \
  --http \
  --http.addr 0.0.0.0 \
  --http.port 8000 \
  --http.api eth,web3,net,txpool,personal,miner \
  --http.corsdomain "*" \
  --port 6000 \
  --datadir chaindbname \
  --networkid 123678 \
  --gcmode archive \
  --bootnodes enode://e10a90e9c7d077002d4d56b88943b8dfbca1d6490bb92c8202e6acb68ef23b521bf187fb40c07eed2f453f3782e8c53ca5a4ec1d34a4454960143501df8c4b95@149.102.156.210:6000
EOS

chmod +x start-cypher.sh

echo "==> Start node with PM2"
/usr/local/bin/pm2 delete cypher-node >/dev/null 2>&1 || true
/usr/local/bin/pm2 start ./start-cypher.sh --name cypher-node
/usr/local/bin/pm2 save

echo "==> Wait for IPC..."
for i in {1..60}; do
  if [ -S ./chaindbname/cypher.ipc ]; then
    break
  fi
  sleep 1
done

if [ ! -S ./chaindbname/cypher.ipc ]; then
  echo "ERROR: IPC not found: ./chaindbname/cypher.ipc"
  echo "Check logs:"
  echo "  /usr/local/bin/pm2 logs cypher-node"
  exit 1
fi

echo
read -rsp "Enter new account password: " ACCOUNT_PASSWORD
echo

echo "==> Create new account"
ADDRESS=$(
  ./build/bin/cypher attach ipc:./chaindbname/cypher.ipc --exec "personal.newAccount(\"$ACCOUNT_PASSWORD\")" \
  | tr -d '"' \
  | tail -n 1
)

echo "Created address: $ADDRESS"

echo "==> Start mining"
RESULT=$(
  ./build/bin/cypher attach ipc:./chaindbname/cypher.ipc --exec "miner.start(1, \"$ADDRESS\", \"$ACCOUNT_PASSWORD\")" \
  | tail -n 1
)

echo "miner.start result: $RESULT"

if [ "$RESULT" = "null" ]; then
  echo
  echo "Mining started successfully."
  echo "Address: $ADDRESS"

  echo
  read -rp "Enter mining reward wallet address: " REWARD_ADDRESS

  echo "==> Set mining reward wallet"
  SET_ETHERBASE_RESULT=$(
    ./build/bin/cypher attach ipc:./chaindbname/cypher.ipc --exec "miner.setEtherbase(\"$REWARD_ADDRESS\")" \
    | tail -n 1
  )

  echo "miner.setEtherbase result: $SET_ETHERBASE_RESULT"
  echo "Mining reward wallet address: $REWARD_ADDRESS"
else
  echo
  echo "Mining command returned unexpected result."
  echo "Please check:"
  echo "  /usr/local/bin/pm2 logs cypher-node"
fi

cd "$(dirname "$0")/cypher" 2>/dev/null || cd "$(pwd)"

echo
echo "PM2 started cypher-node."
echo "Check status with:"
echo "  /usr/local/bin/pm2 status"
echo "  /usr/local/bin/pm2 logs cypher-node"
echo
echo "To enable auto-start after reboot, run:"
echo "  /usr/local/bin/pm2 startup systemd -u $USER --hp $HOME"
echo
echo "Mining will start after the DAG is generated."
echo "Please read the README for some additional operations."
echo
echo "Done."
