$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Get-Sha512 {
    param([string]$Path)
    return (Get-FileHash -Algorithm SHA512 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function ConvertTo-Slug {
    param([string]$Name)
    $slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    return $slug.Trim("-")
}

function Set-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $Value = $Value -replace "`r`n", "`n"
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function ConvertTo-TomlString {
    param([string]$Value)
    return ($Value -replace '\\', '\\' -replace '"', '\"')
}

$jars = Get-ChildItem -Path ".\mods" -Filter "*.jar" -File | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        File = $_
        Sha512 = Get-Sha512 $_.FullName
    }
}

$matches = @{}
$batchSize = 100
for ($offset = 0; $offset -lt $jars.Count; $offset += $batchSize) {
    $batch = @($jars | Select-Object -Skip $offset -First $batchSize)
    $body = @{
        hashes = @($batch | ForEach-Object { $_.Sha512 })
        algorithm = "sha512"
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Method Post -Uri "https://api.modrinth.com/v2/version_files" -Body $body -ContentType "application/json" -Headers @{ "User-Agent" = "AllTheMons-Takes-Off packwiz setup (github.com/yarnobachmann/AllTheMons-Takes-Off)" }
    foreach ($property in $response.PSObject.Properties) {
        $matches[$property.Name] = $property.Value
    }
}

$existingMetafilesByJar = @{}
Get-ChildItem -Path ".\mods" -Filter "*.pw.toml" -File -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content -Raw -LiteralPath $_.FullName
    if ($content -match '(?m)^filename\s*=\s*"([^"]+)"') {
        $existingMetafilesByJar[$Matches[1]] = $_.FullName
    }
}

$matched = New-Object System.Collections.Generic.List[object]
$unmatched = New-Object System.Collections.Generic.List[object]

foreach ($jar in $jars) {
    if ($matches.ContainsKey($jar.Sha512)) {
        $version = $matches[$jar.Sha512]
        $fileInfo = @($version.files | Where-Object { $_.hashes.sha512 -eq $jar.Sha512 } | Select-Object -First 1)
        if (-not $fileInfo) {
            $fileInfo = @($version.files | Select-Object -First 1)
        }

        $base = [System.IO.Path]::GetFileNameWithoutExtension($jar.File.Name)
        $slug = ConvertTo-Slug $base
        $metaPath = Join-Path $jar.File.DirectoryName "$slug.pw.toml"
        $counter = 2
        while ((Test-Path -LiteralPath $metaPath) -and ((Get-Content -Raw -LiteralPath $metaPath) -notmatch [regex]::Escape($jar.File.Name))) {
            $metaPath = Join-Path $jar.File.DirectoryName "$slug-$counter.pw.toml"
            $counter++
        }

        $name = if ([string]::IsNullOrWhiteSpace($version.name)) { $base } else { $version.name }
        $side = "both"
        if ($version.loaders -contains "datapack") { $side = "server" }

        $toml = @"
name = "$(ConvertTo-TomlString $name)"
filename = "$(ConvertTo-TomlString $jar.File.Name)"
side = "$side"

[download]
url = "$(ConvertTo-TomlString $fileInfo.url)"
hash-format = "sha512"
hash = "$($jar.Sha512)"

[update.modrinth]
mod-id = "$($version.project_id)"
version = "$($version.id)"
"@
        Set-Utf8NoBom -Path $metaPath -Value $toml
        $matched.Add([pscustomobject]@{ jar = $jar.File.Name; metafile = (Resolve-Path -LiteralPath $metaPath).Path; project = $version.project_id }) | Out-Null
    } elseif ($existingMetafilesByJar.ContainsKey($jar.File.Name)) {
        $matched.Add([pscustomobject]@{ jar = $jar.File.Name; metafile = $existingMetafilesByJar[$jar.File.Name]; project = "existing" }) | Out-Null
    } else {
        $unmatched.Add([pscustomobject]@{ jar = $jar.File.Name; length = $jar.File.Length }) | Out-Null
    }
}

$gitignoreHeader = @"
# Generated packaging workspace.
dist/prism-staging/
.reference-season3/

# These are represented by generated mods/*.pw.toml files when matched on Modrinth.
mods/.connector/
mods/**/*.jar
mods/*.jar

# Local-only jars that cannot be resolved to Modrinth are added below by scripts/generate-modrinth-metafiles.ps1.
"@
$gitignoreLines = [System.Collections.Generic.List[string]]::new()
$gitignoreLines.Add($gitignoreHeader.TrimEnd())
foreach ($jar in ($unmatched | Sort-Object jar)) {
    $gitignoreLines.Add("!mods/$($jar.jar)")
}
Set-Utf8NoBom -Path ".gitignore" -Value ($gitignoreLines -join "`n")

$report = [System.Collections.Generic.List[string]]::new()
$report.Add("# Modrinth matching report")
$report.Add("")
$report.Add("- Matched jars: $($matched.Count)")
$report.Add("- Local-only jars: $($unmatched.Count)")
$report.Add("")
if ($unmatched.Count -gt 0) {
    $report.Add("## Local-only jars")
    $report.Add("")
    foreach ($jar in ($unmatched | Sort-Object length -Descending)) {
        $mb = [math]::Round($jar.length / 1MB, 2)
        $report.Add(("- `{0}` ({1} MB)" -f $jar.jar, $mb))
    }
}
Set-Utf8NoBom -Path "codex-report.md" -Value ($report -join "`n")

$oversized = @($unmatched | Where-Object { $_.length -ge 100MB })
Write-Host "Matched $($matched.Count) jars on Modrinth."
Write-Host "Kept $($unmatched.Count) local-only jars."
if ($oversized.Count -gt 0) {
    Write-Warning "Some local-only jars are 100 MB or larger and cannot be pushed to GitHub:"
    $oversized | ForEach-Object { Write-Warning " - $($_.jar)" }
}
