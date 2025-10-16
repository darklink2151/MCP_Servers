$cli = Join-Path $PSScriptRoot 'mcp-cli.js'
$cfg = Resolve-Path (Join-Path $PSScriptRoot '..\configs\master-config.json')
node $cli start-autostart -c $cfg
