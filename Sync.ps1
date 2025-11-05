param(
    [switch]$DryRun  # Try
)

# === PATH ===
$pathA = "E:\Data Library\Note"
$pathB = "F:\Note"

# Filter
$excludePatterns = @("*.tmp","*.bak","~*",".DS_Store","Thumbs.db")

# log and conflic
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptRoot "Log"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir ("sync_log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

function Write-Log($msg) {
    $line = "[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date), $msg
    $line | Tee-Object -FilePath $logFile -Append
}

function Ensure-Dir($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
        Write-Log "CreateDir: $path"
    }
}

function Get-RelPath($full, $root) {
    $rel = $full.Substring($root.Length).TrimStart('\')
    return $rel
}

function Should-Exclude($path) {
    foreach ($p in $excludePatterns) {
        if ([System.IO.Path]::GetFileName($path) -like $p) { return $true }
    }
    return $false
}

function Copy-File-Safe($src, $dst) {
    Ensure-Dir (Split-Path -Parent $dst)
    if ($DryRun) {
        Write-Log "COPY (dry): `"$src`" -> `"$dst`""
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        # time stamp
        (Get-Item -LiteralPath $dst).LastWriteTimeUtc = (Get-Item -LiteralPath $src).LastWriteTimeUtc
        Write-Log "COPY: `"$src`" -> `"$dst`""
    }
}

function Backup-To-Conflicts($pathToBackup, $rootSide, $relPath) {
    $conflictRoot = Join-Path $scriptRoot "_conflicts"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dst = Join-Path $conflictRoot (Join-Path $rootSide ($relPath + "." + $stamp))
    Ensure-Dir (Split-Path -Parent $dst)
    if ($DryRun) {
        Write-Log "BACKUP (dry): `"$pathToBackup`" -> `"$dst`""
    } else {
        Copy-Item -LiteralPath $pathToBackup -Destination $dst -Force
        Write-Log "BACKUP: `"$pathToBackup`" -> `"$dst`""
    }
}

# Collect
function Collect($root) {
    if (-not (Test-Path -LiteralPath $root)) { return @{} }
    $files = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue
    $map = @{}
    foreach ($f in $files) {
        if (Should-Exclude $f.FullName) { continue }
        $rel = Get-RelPath $f.FullName $root
        $map[$rel] = @{
            Full = $f.FullName
            Time = $f.LastWriteTimeUtc
            Size = $f.Length
        }
    }
    return $map
}

Write-Log "=== START SYNC ==="
Write-Log "A: $pathA"
Write-Log "B: $pathB"
Write-Log "DryRun: $DryRun"
Write-Log "Exclude: $($excludePatterns -join ', ')"

$A = Collect $pathA
$B = Collect $pathB
$allKeys = New-Object System.Collections.Generic.HashSet[string]
$A.Keys | ForEach-Object { [void]$allKeys.Add($_) }
$B.Keys | ForEach-Object { [void]$allKeys.Add($_) }

foreach ($rel in $allKeys) {
    $inA = $A.ContainsKey($rel)
    $inB = $B.ContainsKey($rel)

    if (-not $inA -and $inB) {
        # Copy to A
        Copy-File-Safe $B[$rel].Full (Join-Path $pathA $rel)
        continue
    }
    if ($inA -and -not $inB) {
        # Copy to B
        Copy-File-Safe $A[$rel].Full (Join-Path $pathB $rel)
        continue
    }
    if ($inA -and $inB) {
        $aMeta = $A[$rel]; $bMeta = $B[$rel]
        $sameSize = ($aMeta.Size -eq $bMeta.Size)
        $sameTime = ($aMeta.Time -eq $bMeta.Time)

        if ($sameSize -and $sameTime) {
            # skip
            continue
        }

        # Renew while save old to _conflicts
        if ($aMeta.Time -gt $bMeta.Time) {
            # A renew
            Backup-To-Conflicts $bMeta.Full "B" $rel
            Copy-File-Safe $aMeta.Full (Join-Path $pathB $rel)
        } elseif ($bMeta.Time -gt $aMeta.Time) {
            # B renew
            Backup-To-Conflicts $aMeta.Full "A" $rel
            Copy-File-Safe $bMeta.Full (Join-Path $pathA $rel)
        } else {
            # Size different: A cover B
            Backup-To-Conflicts $aMeta.Full "A" $rel
            Backup-To-Conflicts $bMeta.Full "B" $rel
            Copy-File-Safe $aMeta.Full (Join-Path $pathB $rel)
        }
    }
}

Write-Log "=== DONE ==="
Write-Log "Log saved: $logFile"