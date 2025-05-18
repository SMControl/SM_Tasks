Write-Host "PDTWifi64_Daily_Restart.ps1 - Version 1.1"
# Creates a scheduled task to restart the PDTWiFi64 application daily at 5:00 AM.
# Recent Changes
# Version 1.1 - Reduced user messaging.

# Part 1 - Define Task Parameters
# PartVersion-1.1
# -----
$TaskName = "SO_PDTWifi64_Daily_Restart"
$Description = "Restarts PDTWiFi at 5am Daily"
$ActionExecute = "powershell.exe"
$ActionArgument = "-Command if (Get-Process -Name PDTWiFi64 -ErrorAction SilentlyContinue) { Stop-Process -Name PDTWiFi64 -Force; Start-Sleep 5 }; Start-Process 'C:\Program Files (x86)\StationMaster\PDTWiFi64.exe'"
$TriggerDaily = (New-ScheduledTaskTrigger -Daily -At 5:00AM)
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"

# Part 2 - Create Scheduled Task Action
# PartVersion-1.1
# -----
$Action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument

# Part 3 - Create Scheduled Task Principal
# PartVersion-1.1
# -----
$Principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

# Part 4 - Register the Scheduled Task
# PartVersion-1.1
# -----
try {
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $TriggerDaily -Principal $Principal -Force
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
}
catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
