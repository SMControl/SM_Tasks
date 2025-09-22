Write-Host "SO_PDTWifi64_Daily_Restart.ps1 - Version 1.2"
# ScriptVersion-1.2
# Creates a scheduled task to restart the PDTWiFi64 application daily at 5:00 AM and at user logon.
# Recent Changes
# Version 1.1 - Reduced user messaging.
# Version 1.2 - Added user logon trigger.

# Part 1 - Define Task Parameters
# PartVersion-1.2
#LOCK=ON
# -----
$TaskName = "SO PDTWifi64_Daily_Restart"
$Description = "Restarts PDTWiFi64 at 5am Daily and at user logon"
$ActionExecute = "powershell.exe"
$ActionArgument = "-Command if (Get-Process -Name PDTWiFi64 -ErrorAction SilentlyContinue) { Stop-Process -Name PDTWiFi64 -Force; Start-Sleep 5 }; Start-Process 'C:\Program Files (x86)\StationMaster\PDTWiFi64.exe'"
$TriggerDaily = (New-ScheduledTaskTrigger -Daily -At 5:00AM)
$TriggerLogon = (New-ScheduledTaskTrigger -AtLogon) # New trigger for user logon
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"

# Part 2 - Create Scheduled Task Action
# PartVersion-1.1
#LOCK=ON
# -----
$Action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument

# Part 3 - Create Scheduled Task Principal
# PartVersion-1.1
#LOCK=ON
# -----
$Principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

# Part 4 - Register the Scheduled Task
# PartVersion-1.2
#LOCK=ON
# -----
try {
    # Combine both triggers into an array
    $Triggers = @($TriggerDaily, $TriggerLogon)
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $Triggers -Principal $Principal -Force
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully with daily and logon triggers."
}
catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
