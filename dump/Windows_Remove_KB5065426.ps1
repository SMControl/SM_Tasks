# Script Version: 3.0

# This script first uninstalls a specified Windows update and then blocks it from reinstalling.

# Part 1: Define Variables and Uninstall the Update
# PartVersion: 1.0
#LOCK=OFF

$UpdateToManage = "KB5065426"
$UninstallCommand = "wusa.exe /uninstall /kb:$UpdateToManage /quiet /norestart"
# Check if the update is installed before trying to uninstall it.
$installedUpdates = Get-HotFix | Where-Object { $_.HotFixID -eq $UpdateToManage }

if ($installedUpdates) {
    Write-Host "Found update '$UpdateToManage'. Attempting to uninstall..." -ForegroundColor Yellow
    
    try {
        # Run the uninstall command silently.
        Start-Process -FilePath wusa.exe -ArgumentList "/uninstall /kb:$UpdateToManage /quiet /norestart" -Wait -NoNewWindow
        
        Write-Host "Uninstallation of '$UpdateToManage' started. A restart may be required." -ForegroundColor Green
        
        # We can add a user prompt here to restart the machine to complete the uninstallation
        # The restart part of this script is commented out by default.
        # Uncomment the lines below if you want the script to prompt for a restart.
        
        # Write-Host "A restart is required to complete the uninstallation." -ForegroundColor Yellow
        # $choice = Read-Host "Do you want to restart now to complete the process? (Y/N)"
        # if ($choice -eq 'Y' -or $choice -eq 'y') {
        #    Restart-Computer -Force
        # }
    }
    catch {
        Write-Host "Failed to uninstall update '$UpdateToManage'. Error: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Update '$UpdateToManage' is not installed. Skipping uninstallation." -ForegroundColor Cyan
}

# Part 2: Block the Update from Reinstalling
# PartVersion: 1.0
#LOCK=OFF

$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\ExcludeWUDrivers"

# Check if the registry path exists, create it if not.
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}

# Create the registry key to block the update.
try {
    Set-ItemProperty -Path $RegistryPath -Name $UpdateToManage -Value 1 -Type DWord -Force | Out-Null
    Write-Host "Update '$UpdateToManage' is now blocked from reinstalling." -ForegroundColor Green
}
catch {
    Write-Host "Failed to block update '$UpdateToManage'." -ForegroundColor Red
}
