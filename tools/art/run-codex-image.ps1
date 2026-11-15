param([string]$PromptFile, [string]$OutDir, [string[]]$Image)
# -Image: optional reference image(s) attached to the prompt (absolute paths).
$exe = (Get-ChildItem (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin') -Directory | ForEach-Object { Join-Path $_.FullName 'codex.exe' } | Where-Object { Test-Path $_ } | Select-Object -First 1)
New-Item -ItemType Directory -Force $OutDir | Out-Null
$p = Get-Content -Raw $PromptFile
$imgArgs = @()
foreach ($i in $Image) { if ($i) { $imgArgs += @('-i', (Resolve-Path $i).Path) } }
& $exe exec --skip-git-repo-check -s workspace-write -C $OutDir @imgArgs -- $p 2>&1 | Select-Object -Last 15
