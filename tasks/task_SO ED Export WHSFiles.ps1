Write-Host "task_SO ED Export WHSFiles.ps1 - Version 1.2"
# ScriptVersion-1.2
# Checks for and creates a scheduled task to run SOScheduler.exe with the EDBULLETINS argument every 5 minutes, 24 hours a day.
# Recent Changes
# Version 1.2 - Implemented highly compatible method for setting trigger repetition by creating a dedicated Repetition object to fix 'Interval' property error.
# Version 1.1 - Fixed 'RepetitionInterval' parameter error for older PowerShell versions by setting repetition properties directly on the trigger (later found to be incompatible).

# Part 1 - Check if scheduled task exists and define parameters
# PartVersion 1.0
#LOCK=OFF
# -----
$TaskName = "SO ED Export WHSFiles"

Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $Description = "Executes the SOScheduler EDBULLETINS argument every 5 minutes, 24/7."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "EDBULLETINS"
    
    # Define Scheduled Task Principal (Uses current interactive user context)
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"

    # Part 2 - Define Action, Triggers, and Settings
    # PartVersion 1.2
    #LOCK=OFF
    # -----
    $action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
    
    # Define the trigger: Daily, starting at midnight
    $trigger = New-ScheduledTaskTrigger -Daily -At "00:00 AM"

    # --- HIGH-COMPATIBILITY REPETITION FIX ---
    # 1. Create a Repetition object
    $repetition = New-Object -TypeName Microsoft.PowerShell.Commands.ScheduledTask.RepetitionPattern
    # 2. Set the Interval and Duration properties on the Repetition object
    $repetition.Interval = (New-TimeSpan -Minutes 5)
    $repetition.Duration = (New-TimeSpan -Days 1)
    # 3. Assign the complete Repetition object to the trigger
    $trigger.Repetition = $repetition
    # ----------------------------------------

    Write-Host "Scheduled time set to repeat every 5 minutes for 24 hours, starting daily at 00:00 AM."

    # Define settings: Hidden, 30 min timeout, and StartWhenAvailable
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
        -StartWhenAvailable:$true
        
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
