# Prerequisites
# DAG Memory Requirements
The DAG size starts at 32 GB and stays resident in VRAM.
For stable operation, at least 96 GB of system VRAM is recommended.
## Your own password  
Required for the `cypher-colossusx` account.  
(Any password is OK)

## Your EVM address for receiving mining rewards  
(0x address)

After preparing those, simply copy and paste the command below into your machine and press Enter.

# Linux ueser

```bash
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/CypherTroopers/onclick-colossusX/main/colossusX_linux.sh)" root
```

# Windows powershell user
```bash
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/CypherTroopers/onclick-colossusX/main/colossusX_powershell.ps1 | iex"
```
# Mac(Apple silicon User)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/CypherTroopers/onclick-colossusX/main/colossusX_arm64.sh)
```
