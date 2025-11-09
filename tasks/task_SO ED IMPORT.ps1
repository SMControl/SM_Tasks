Write-Host "task_SO ED IMPORT.ps1 - Version 1.0"
# ScriptVersion-1.0
# Checks for and creates a scheduled task to run SOScheduler.exe with the EDIMPORT argument every 5 minutes, 24 hours a day.

# Part 1 - Check if scheduled task exists and define parameters
# PartVersion 1.0
#LOCK=OFF
# -----
$TaskName = "SO ED IMPORT"

Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $Description = "Executes the SOScheduler EDIMPORT argument every 5 minutes, 24/7."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "EDIMPORT"
    
    # Define Scheduled Task Principal (Uses current interactive user context)
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"

    # Part 2 - Define Action, Triggers, and Settings
    # PartVersion 1.0
    #LOCK=OFF
    # -----
    $action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
    
    # Define the trigger: Daily, starting at midnight
    # The repetition setting below handles the 5-minute execution frequency.
    $trigger = New-ScheduledTaskTrigger -Daily -At "00:00 AM"

    Write-Host "Scheduled time set to repeat every 5 minutes for 24 hours, starting daily at 00:00 AM."

    # Define settings: Hidden, 30 min timeout, repeat every 5 minutes for 1 day
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
        -RepetitionInterval (New-TimeSpan -Minutes 5) `
        -RepetitionDuration (New-TimeSpan -Days 1) `
        -StartWhenAvailable:$true # This ensures the task runs immediately after a system restart if it was missed.
        
    $principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

    # Part 3 - Register the Scheduled Task
    # PartVersion 1.0
    #LOCK=OFF
    # -----
    try {
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' already exists. No action needed."
}
