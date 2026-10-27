param([string]$PromptFile, [string]$OutDir)
$exe = (Get-ChildItem (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin') -Directory | ForEach-Object { Join-Path $_.FullName 'codex.exe' } | Where-Object { Test-Path $_ } | Select-Object -First 1)
New-Item -ItemType Directory -Force $OutDir | Out-Null
$p = Get-Content -Raw $PromptFile
& $exe exec --skip-git-repo-check -s workspace-write -C $OutDir $p 2>&1 | Select-Object -Last 15
