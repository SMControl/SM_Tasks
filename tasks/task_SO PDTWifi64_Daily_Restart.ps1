# ScriptVersion-1.3
Write-Host "SO_PDTWifi64_Daily_Restart.ps1 - Version 1.3"
$TaskName = "SO PDTWifi64_Daily_Restart"
$Description = "Restarts PDTWiFi64 at 5am Daily and at user logon"
$ActionExecute = "powershell.exe"
$ActionArgument = "-Command if (Get-Process -Name PDTWiFi64 -ErrorAction SilentlyContinue) { Stop-Process -Name PDTWiFi64 -Force; Start-Sleep 5 }; Start-Process 'C:\Program Files (x86)\StationMaster\PDTWiFi64.exe'"
$TriggerDaily = (New-ScheduledTaskTrigger -Daily -At 5:00AM)
$TriggerLogon = (New-ScheduledTaskTrigger -AtLogon)
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"
$Action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
$Principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel
try {
    $Triggers = @($TriggerDaily, $TriggerLogon)
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $Triggers -Principal $Principal -Force
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully with daily and logon triggers."
} catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
