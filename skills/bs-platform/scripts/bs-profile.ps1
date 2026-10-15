<#
.SYNOPSIS
  Prints a BS Platform repo profile and flags drift the skill warns about.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bs-profile.ps1 -Root D:\path\to\repo
#>
param(
  [string]$Root = (Get-Location).Path,
  [string]$MuiXVersion = '7.29.9'  # team MUI X license version
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path $Root).Path
$issues = 0
function Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:issues++ }

# ponytail: depth-limited scan, skips build output; deeper monorepos need -Root pointed closer
function Find-Files($filter) {
  Get-ChildItem -Path $Root -Recurse -Depth 5 -Filter $filter -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(node_modules|bin|obj|build|dist|\.git|\.claude|[^\\]*worktrees)\\' }
}

Write-Host "BS Platform profile: $Root"

# --- Frontend -------------------------------------------------------------
foreach ($pkgFile in Find-Files 'package.json' | Where-Object { $_.Directory.Name -eq 'Frontend-Core' }) {
  $dir = $pkgFile.Directory.FullName
  $pkg = Get-Content $pkgFile.FullName -Raw | ConvertFrom-Json
  $deps = $pkg.dependencies
  Write-Host "`n[Frontend] $dir"
  Write-Host "  homepage        : $($pkg.homepage)"
  foreach ($n in 'react', 'react-router-dom', '@mui/material', '@mui/x-data-grid', '@mui/x-data-grid-pro') {
    Write-Host ("  {0,-22}: {1}" -f $n, $deps.$n)
  }
  $locks = @('package-lock.json', 'pnpm-lock.yaml', 'yarn.lock') | Where-Object { Test-Path (Join-Path $dir $_) }
  Write-Host "  lockfile        : $($locks -join ', ')"
  if (-not $locks) { Warn 'no lockfile - installs are not reproducible' }
  if ($locks.Count -gt 1) { Warn 'multiple lockfiles - pick one package manager' }

  # MUI X license covers exactly $MuiXVersion: declared spec and every lockfile copy must match
  foreach ($n in '@mui/x-data-grid', '@mui/x-data-grid-pro') {
    if ($deps.$n -and $deps.$n -ne $MuiXVersion) { Warn "package.json $n is '$($deps.$n)', must be exactly '$MuiXVersion'" }
  }
  $lockFile = Join-Path $dir 'package-lock.json'
  if (Test-Path $lockFile) {
    # regex instead of ConvertFrom-Json: PS 5.1 rejects the lockfile's empty "" package key
    $lock = Get-Content $lockFile -Raw
    $muiX = [regex]::Matches($lock, '"(node_modules/(?:[^"]*/)?@mui/x-data-grid(?:-pro)?)"\s*:\s*\{\s*"version"\s*:\s*"([^"]+)"')
    foreach ($e in $muiX) {
      $path = $e.Groups[1].Value; $ver = $e.Groups[2].Value
      Write-Host ("  lock {0,-52}: {1}" -f $path, $ver)
      if ($ver -ne $MuiXVersion) { Warn "lockfile $path is $ver, license requires $MuiXVersion ('Expired package version' risk)" }
    }
  }

  foreach ($envName in '.env.development', '.env.production') {
    $envFile = Join-Path $dir $envName
    if (Test-Path $envFile) {
      $base = (Select-String -Path $envFile -Pattern '^\s*REACT_APP_BASE_URL\s*=\s*(.*)$' | Select-Object -First 1)
      $api = (Select-String -Path $envFile -Pattern '^\s*REACT_APP_API_URL\s*=\s*(.*)$' | Select-Object -First 1)
      Write-Host ("  {0,-16}: BASE_URL={1} API_URL={2}" -f $envName,
        $(if ($base) { $base.Matches[0].Groups[1].Value } else { '-' }),
        $(if ($api) { $api.Matches[0].Groups[1].Value } else { '-' }))
    }
  }
}

# --- Gateway coverage for DynamicController --------------------------------
$ocelot = Find-Files 'ocelot.json' | Select-Object -First 1
$dynamic = Find-Files 'DynamicController.cs' | Select-Object -First 1
if ($ocelot) {
  $routes = (Get-Content $ocelot.FullName -Raw | ConvertFrom-Json).Routes
  $upstreams = $routes | ForEach-Object { $_.UpstreamPathTemplate.ToLower() }
  Write-Host "`n[Gateway] $($ocelot.FullName) - $($routes.Count) routes"
  $routes | Group-Object { $_.DownstreamHostAndPorts[0].Host } | Sort-Object Count -Descending |
    ForEach-Object { Write-Host ("  {0,-26}: {1} routes" -f $_.Name, $_.Count) }
  $noAuth = $routes | Where-Object { -not $_.AuthenticationOptions.AuthenticationProviderKey }
  Write-Host "  anonymous routes: $(($noAuth | ForEach-Object { $_.UpstreamPathTemplate }) -join ', ')"

  if ($dynamic) {
    $ops = Select-String -Path $dynamic.FullName -Pattern '\[Http\w+\("([^"]+)"\)\]' |
      ForEach-Object { $_.Matches[0].Groups[1].Value }
    Write-Host "`n[DynamicController] $($ops.Count) operations"
    foreach ($op in $ops) {
      if ($upstreams -notcontains "/gateway/v1/api/dynamic/$op".ToLower()) {
        Warn "api/dynamic/$op has no ocelot route (frontend calls through the gateway will 404)"
      }
    }
  }
}

# --- Core API config --------------------------------------------------------
foreach ($cfg in Find-Files 'appsettings.json' | Where-Object { $_.Directory.Name -eq 'ApiCore' }) {
  $m = Select-String -Path $cfg.FullName -Pattern '"AllowedSchemas"\s*:\s*\[([^\]]*)\]' | Select-Object -First 1
  if ($m) { Write-Host "`n[ApiCore] AllowedSchemas: $($m.Matches[0].Groups[1].Value -replace '\s|"', '')" }
}

# --- Docker compose ---------------------------------------------------------
$compose = Get-ChildItem -Path $Root -Filter 'docker-compose.yml' -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($compose) {
  $section = ''; $services = @()
  foreach ($line in Get-Content $compose.FullName) {
    if ($line -match '^([a-z]+):') { $section = $Matches[1] }
    elseif ($section -eq 'services' -and $line -match '^  ([A-Za-z0-9_-]+):\s*$') { $services += $Matches[1] }
  }
  Write-Host "`n[docker-compose] $($services -join ', ')"
}

Write-Host "`nDone. $issues warning(s)."
exit [int]($issues -gt 0)
