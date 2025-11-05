param(
  [Parameter(Mandatory=$true)][string]$A,
  [Parameter(Mandatory=$true)][string]$B,
  [switch]$DryRun
)

# Simple two-way copy using robocopy (newer only, no delete)
$Excludes = @('.git','.svn','.DS_Store','Thumbs.db','~$*')
$LogDir   = Join-Path $PSScriptRoot 'logs'
$ts       = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile  = Join-Path $LogDir "sync_$ts.log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Log($m){("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m) |
  Tee-Object -FilePath $LogFile -Append | Out-Null}

Log "=== START ==="
Log "A: $A"
Log "B: $B"
if($DryRun){Log "Mode: DryRun"}else{Log "Mode: Normal"}

$opts = @('/E','/XO','/XN','/R:2','/W:2','/Z','/NP','/NFL','/NDL',"/LOG+:$LogFile")
if($DryRun){$opts += '/L'}
if($Excludes.Count){$opts += @('/XA:SH','/XD')+$Excludes+@('/XF')+$Excludes}

Log "A -> B"
& robocopy $A $B $opts | Out-Null
Log "B -> A"
& robocopy $B $A $opts | Out-Null

Log "=== DONE ==="
Write-Host "Done. Log: $LogFile"