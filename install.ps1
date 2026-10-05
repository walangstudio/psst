$ErrorActionPreference = 'Stop'
$dest = if ($env:CLAUDE_COMMANDS_DIR) { $env:CLAUDE_COMMANDS_DIR } else { Join-Path $HOME '.claude\commands' }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'commands\*.md') $dest -Force
Write-Host "installed /sonnet /s /haiku /h /opus /o /fable /f -> $dest"
