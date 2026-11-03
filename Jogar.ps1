$ErrorActionPreference = 'Stop'
$projectDirectory = $PSScriptRoot
$candidates = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Godot_v4.7.2-stable_win64.exe'),
    (Join-Path $env:USERPROFILE 'Downloads\Godot_v4.7.2-stable_win64.exe')
)
$engine = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $engine) {
    $installed = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($installed) { $engine = $installed.Source }
}
if (-not $engine) {
    Write-Host 'Abra project.godot no Godot 4 e pressione F5.'
    exit 1
}
& $engine --path $projectDirectory
