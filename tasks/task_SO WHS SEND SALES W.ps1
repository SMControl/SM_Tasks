# ScriptVersion-1.1
Write-Host "task_SO WHS SEND SALES W.ps1 - Version 1.1"
$TaskName = "SO WHS SEND SALES W"
Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."
    $Description = "Executes the SOScheduler WHSSENDSALES W argument weekly on Sunday and Monday."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "WHSSENDSALES W"
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"
    $action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
    $randomHour = Get-Random -Minimum 2 -Maximum 5
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute
    Write-Host "Scheduled time set to a random time between 02:00 and 04:00 weekly: $randomTime"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday, Monday -At $randomTime
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    $principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel
    try {
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
    } catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' already exists. No action needed."
}
