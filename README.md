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
Because a huge DAG is pre-generated, the time required before mining actually starts depends on your environment (usually around 5 to 30 minutes).

A few minutes after running the script, you will be asked to enter a password.
This is the password for your colossusx mining account.
It can be any length.
However, if you forget this password, you will not be able to restart mining after a node restart or server downtime, and you will need to create a new mining account.
Do not forget it.
![image](https://github.com/user-attachments/assets/8a0d3a5b-59cf-40fa-81fd-0f33a448804f)
Next, you will need to enter the wallet address for receiving mining rewards.

This should be your normal EVM wallet address, such as a MetaMask wallet address.
Mining rewards will be sent to that wallet.