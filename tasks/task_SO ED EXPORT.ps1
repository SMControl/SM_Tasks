# ScriptVersion-1.3
Write-Host "task_SO ED EXPORT.ps1 - Version 1.3"
$TaskName = "SO ED EXPORT"
Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
$Description = "Executes the SOScheduler EDEXPORT argument every 5 minutes, 24/7."
$ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
$ActionArgument = "EDEXPORT"
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$LogonType = "/IT"
Write-Host "Scheduled time set to repeat every 5 minutes for 24 hours, starting daily at 00:00:00."
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
    $result = schtasks.exe /create /tn "$TaskName" /tr "`"$ActionExecute`" $ActionArgument" /sc DAILY /st 00:00:00 /ri 5 /du 24:00 /rl HIGHEST /it /f
    if ($result -match "SUCCESS") {
        Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully via schtasks.exe."
    } else {
        Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName' via schtasks.exe."
        Write-Host -ForegroundColor Red "schtasks.exe output: $result"
    }
} catch {
    Write-Host -ForegroundColor Red "Error executing task registration: $($_.Exception.Message)"
}
