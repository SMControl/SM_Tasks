Write-Host "task_SO PROCESS SALES.ps1 - Version 1.2"
$TaskName = "SO PROCESS SALES"
Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
# Define task parameters
$Description = "PROCESS SALES daily at 5am"
$ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
$ActionArgument = "PROCESSSALES"
# Define Scheduled Task Principal (Uses current interactive user context)
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"

# Part 2 - Define Action, Triggers, and Settings
$action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
# Define daily trigger at 5:00 AM
$Trigger5AM = (New-ScheduledTaskTrigger -Daily -At "05:00 AM")
Write-Host "Scheduled time set to 05:00 AM daily."
# ExecutionTimeLimit increased to 2 hours, StartWhenAvailable enabled to run if missed
$settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Hours 2) -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

# Part 3 - Register the Scheduled Task
try {
    if (-not $taskExists) {
        Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."
    }
    else {
        Write-Host -ForegroundColor Yellow "Task already exists. Re-registering to update settings..."
    }

    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $Trigger5AM -Settings $settings -Principal $principal -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
}
catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
