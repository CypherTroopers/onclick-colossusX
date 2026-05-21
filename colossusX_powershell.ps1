$ErrorActionPreference = "Stop"

Write-Host "==> Install Git and Node.js"

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --source winget
} else {
    Write-Host "Git already installed. Skip."
}

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    winget install --id OpenJS.NodeJS.LTS -e --source winget
} else {
    Write-Host "Node.js already installed. Skip."
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "==> Install PM2"

if (!(Get-Command pm2 -ErrorAction SilentlyContinue)) {
    npm install -g pm2
} else {
    Write-Host "PM2 already installed. Skip."
}

Write-Host "==> Clone Cypherium repo"

if (!(Test-Path ".\cypher")) {
    git clone https://github.com/CypherTroopers/cypher.git
}

Set-Location .\cypher

Write-Host "==> Init chaindbname"

.\build\bin\cypher.exe --datadir .\chaindbname init .\genesistest.json

Write-Host "==> Create start-cypher.ps1"

@'
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

$ExtIP = (Invoke-RestMethod -Uri "https://api4.ipify.org").Trim()

.\build\bin\cypher.exe `
  --verbosity 4 `
  --rnetport 7200 `
  --syncmode full `
  --nat "extip:$ExtIP" `
  --ws `
  --ws.addr 0.0.0.0 `
  --ws.port 9251 `
  --ws.origins "*" `
  --metrics `
  --http `
  --http.addr 0.0.0.0 `
  --http.port 8000 `
  --http.api eth,web3,net,txpool,personal,miner `
  --http.corsdomain "*" `
  --port 6000 `
  --datadir .\chaindbname `
  --networkid 123678 `
  --gcmode archive `
  --bootnodes "enode://e10a90e9c7d077002d4d56b88943b8dfbca1d6490bb92c8202e6acb68ef23b521bf187fb40c07eed2f453f3782e8c53ca5a4ec1d34a4454960143501df8c4b95@149.102.156.210:6000"
'@ | Set-Content -Encoding UTF8 .\start-cypher.ps1

Write-Host "==> Start node with PM2"

pm2 describe cypher-node >$null 2>&1
if ($LASTEXITCODE -eq 0) {
    pm2 delete cypher-node
} else {
    Write-Host "cypher-node not found in PM2. Skip delete."
}

pm2 start powershell --name cypher-node -- `
  -ExecutionPolicy Bypass `
  -File "$PWD\start-cypher.ps1"

pm2 save

Write-Host "==> Wait for IPC..."

$PipePath = "\\.\pipe\cypher.ipc"

for ($i = 1; $i -le 60; $i++) {
    if (Test-Path $PipePath) {
        break
    }

    Start-Sleep -Seconds 1
}

if (!(Test-Path $PipePath)) {
    Write-Host "ERROR: IPC not found: $PipePath"
    Write-Host "Check logs:"
    Write-Host "  pm2 logs cypher-node"
    exit 1
}

Write-Host ""

$ACCOUNT_PASSWORD = Read-Host "Enter new account password" -AsSecureString

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ACCOUNT_PASSWORD)

$ACCOUNT_PASSWORD_TEXT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "==> Create new account"

$ADDRESS = .\build\bin\cypher.exe attach ipc:\\.\pipe\cypher.ipc `
  --exec "personal.newAccount(`"$ACCOUNT_PASSWORD_TEXT`")"

$ADDRESS = $ADDRESS.Replace('"','').Trim().Split("`n")[-1].Trim()

Write-Host "Created address: $ADDRESS"

Write-Host ""
Write-Host "==> Start mining"

$RESULT = .\build\bin\cypher.exe attach ipc:\\.\pipe\cypher.ipc `
  --exec "miner.start(1, `"$ADDRESS`", `"$ACCOUNT_PASSWORD_TEXT`")"

$RESULT = $RESULT.Trim().Split("`n")[-1].Trim()

Write-Host "miner.start result: $RESULT"

if ($RESULT -eq "null") {

    Write-Host ""
    Write-Host "Mining started successfully."
    Write-Host "Address: $ADDRESS"

    Write-Host ""

    $REWARD_ADDRESS = Read-Host "Enter mining reward wallet address"

    Write-Host ""
    Write-Host "==> Set mining reward wallet"

    $SET_ETHERBASE_RESULT = .\build\bin\cypher.exe attach ipc:\\.\pipe\cypher.ipc `
      --exec "miner.setEtherbase(`"$REWARD_ADDRESS`")"

    $SET_ETHERBASE_RESULT = $SET_ETHERBASE_RESULT.Trim().Split("`n")[-1].Trim()

    Write-Host "miner.setEtherbase result: $SET_ETHERBASE_RESULT"
    Write-Host "Mining reward wallet address: $REWARD_ADDRESS"

} else {

    Write-Host ""
    Write-Host "Mining command returned unexpected result."
    Write-Host "Please check:"
    Write-Host "  pm2 logs cypher-node"

}

Write-Host ""
Write-Host "PM2 started cypher-node."

Write-Host ""
Write-Host "Check status with:"
Write-Host "  pm2 status"
Write-Host "  pm2 logs cypher-node"

Write-Host ""
Write-Host "To enable auto-start after reboot, run:"
Write-Host "  pm2 startup"

Write-Host ""
Write-Host "Mining will start after the DAG is generated."

Write-Host ""
Write-Host "Done."
