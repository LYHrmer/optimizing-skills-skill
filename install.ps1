# install.ps1 — Windows installer for the optimizing-skills skill.
$ErrorActionPreference = "Stop"
$src  = Split-Path -Parent $MyInvocation.MyCommand.Path
$name = "optimizing-skills"
$installed = 0
foreach ($base in @("$HOME\.claude\skills", "$HOME\.codex\skills")) {
    $parent = Split-Path -Parent $base
    if (-not (Test-Path $parent)) { Write-Host "skip: $parent 不存在(对应工具未安装)"; continue }
    if (-not (Test-Path $base)) { New-Item -ItemType Directory -Path $base | Out-Null }
    $dest = Join-Path $base $name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $src $dest
    $gitDir = Join-Path $dest ".git"
    if (Test-Path $gitDir) { Remove-Item -Recurse -Force $gitDir }
    Write-Host "copied -> $dest"
    $installed++
}
if ($installed -gt 0) { Write-Host "OK installed to $installed target(s)" }
else { Write-Host "未发现 Claude/Codex skills 目录" }
