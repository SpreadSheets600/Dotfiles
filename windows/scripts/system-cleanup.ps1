<#
    Windows Cleanup Script
    -----------------------
    Author: SpreadSheets600
    Description: Deep cleans temporary files, caches, recycle bin, logs, etc.
    Run as: Administrator
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Please Run This As Administrator." -ForegroundColor Yellow
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Add timestamped logging
$LogPath = "$env:TEMP\cleanup_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
"=== Cleanup Started At $(Get-Date) ===`n" | Out-File -FilePath $LogPath -Encoding UTF8

function Log {
    param([string]$msg)
    $msg | Tee-Object -FilePath $LogPath -Append
}

Write-Host "Starting System Cleanup ..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# --- Helper Function: Safe Delete ---
function Remove-Safe {
    param([string]$path)
    $isWildcard = $path -match "[\*\?\[]"
    $exists = if ($isWildcard) { Test-Path -Path $path } else { Test-Path -LiteralPath $path }
    if ($exists) {
        try {
            if ($isWildcard) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            }
            else {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
            }
            Log "Deleted : $path"
        }
        catch {
            Log "Failed To Delete : $path - $($_.Exception.Message)"
        }
    }
}

# --- TEMP and CACHE ---
Write-Host "`nClearing Temporary Files ..." -ForegroundColor Cyan
Remove-Safe "$env:TEMP\*"
Remove-Safe "C:\Windows\Temp\*"

# --- Recycle Bin ---
Write-Host "`nEmptying Recycle Bin ..." -ForegroundColor Cyan
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Log "Recycle Bin Emptied"
}
catch {
    Log "Recycle Bin Cleanup Failed : $($_.Exception.Message)"
}

# --- Prefetch ---
Write-Host "`nClearing Prefetch Files ..." -ForegroundColor Cyan
Remove-Safe "C:\Windows\Prefetch\*"

# --- Windows Update Cache ---
Write-Host "`nCleaning Windows Update cache ..." -ForegroundColor Cyan
try { Stop-Service wuauserv -Force -ErrorAction Stop } catch {}

Remove-Safe "C:\Windows\SoftwareDistribution\Download\*"
try { Start-Service wuauserv -ErrorAction Stop } catch {}

# --- System Logs ---
Write-Host "`nClearing System Logs ..." -ForegroundColor Cyan
Get-EventLog -List -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        Clear-EventLog -LogName $_.Log -ErrorAction Stop
        Log "Cleared Log: $($_.Log)"
    }
    catch {
        Log "Failed To Clear Log : $($_.Log) - $($_.Exception.Message)"
    }
}

# --- DNS Cache ---
Write-Host "`nFlushing DNS cache ..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
Log "DNS cache flushed"

# --- Browser Caches (Chrome / Edge / Brave / Firefox) ---
Write-Host "`nClearing Browser Caches ..." -ForegroundColor Cyan
$BrowserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2"
)
foreach ($p in $BrowserPaths) { Remove-Safe $p }

# --- Summary ---
Write-Host "`nCleanup Complete." -ForegroundColor Green
Write-Host "Log Saved To : $LogPath" -ForegroundColor DarkGray
Read-Host "Press Enter To Exit... "
