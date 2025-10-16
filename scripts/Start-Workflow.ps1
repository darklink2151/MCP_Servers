param(
  [Parameter(Position=0)][string]$Workflow = "development"
)
$cli = Join-Path $PSScriptRoot 'mcp-cli.js'
$cfg = Resolve-Path (Join-Path $PSScriptRoot '..\configs\master-config.json')
node $cli start-workflow $Workflow -c $cfg
