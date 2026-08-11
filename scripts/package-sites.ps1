param(
  [Parameter(Mandatory = $true)]
  [string]$ArchivePath
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$stageRoot = Join-Path $env:TEMP ('shiome-package-' + [guid]::NewGuid().ToString('N'))
$resolvedTemp = [IO.Path]::GetFullPath($env:TEMP)
$resolvedStage = [IO.Path]::GetFullPath($stageRoot)
if (-not $resolvedStage.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Unsafe staging path'
}
try {
  New-Item -ItemType Directory -Path (Join-Path $stageRoot 'dist\.openai') -Force | Out-Null
  Copy-Item -Path (Join-Path $sourceRoot 'dist\*') -Destination (Join-Path $stageRoot 'dist') -Recurse -Force
  Copy-Item -LiteralPath (Join-Path $sourceRoot '.openai\hosting.json') -Destination (Join-Path $stageRoot 'dist\.openai\hosting.json') -Force
  $drizzleSource = Join-Path $sourceRoot 'drizzle'
  if (Test-Path -LiteralPath $drizzleSource) {
    New-Item -ItemType Directory -Path (Join-Path $stageRoot 'dist\.openai\drizzle') -Force | Out-Null
    Copy-Item -Path (Join-Path $drizzleSource '*') -Destination (Join-Path $stageRoot 'dist\.openai\drizzle') -Recurse -Force
  }
  & tar.exe -C $stageRoot -czf $ArchivePath dist
  if ($LASTEXITCODE -ne 0) { throw 'Archive creation failed' }
  $entries = & tar.exe -tzf $ArchivePath
  if ($entries -notcontains 'dist/server/index.js') { throw 'Missing worker in archive' }
  if ($entries -notcontains 'dist/.openai/hosting.json') { throw 'Missing hosting metadata in archive' }
  if ((Test-Path -LiteralPath $drizzleSource) -and -not ($entries -contains 'dist/.openai/drizzle/0000_posts.sql')) { throw 'Missing database migration in archive' }
  Get-Item -LiteralPath $ArchivePath | Select-Object FullName, Length
}
finally {
  if (Test-Path -LiteralPath $resolvedStage) {
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
  }
}
