# ScriptVersion-1.4
Write-Host "task_SO PROCESS SALES.ps1 - Version 1.4"
$TaskName = "SO PROCESS SALES"
Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
$Description = "PROCESS SALES daily at 1:15am"
$ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
$ActionArgument = "PROCESSSALES"
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"
$action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
$Trigger0115 = (New-ScheduledTaskTrigger -Daily -At "01:15 AM")
Write-Host "Scheduled time set to 01:15 AM daily."
$settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Hours 2) -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel
try {
    if ($taskExists) {
        Write-Host -ForegroundColor Yellow "Task already exists. Deleting it..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Waiting 5 seconds..."
        Start-Sleep -Seconds 5
        Write-Host -ForegroundColor Green "Creating a new scheduled task..."
    } else {
        Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."
    }
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $Trigger0115 -Settings $settings -Principal $principal -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
} catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
