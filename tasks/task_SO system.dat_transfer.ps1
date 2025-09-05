# ScriptVersion-1.4
# Checks for and creates a scheduled task to run SO_Scheduler.exe with the TRANSFER_SP_CONFIG argument at a random time between 00:00 AM and 04:00 AM daily.
# Recent Changes
# Version 1.4 - Added a descriptive name for the task.
# Version 1.3 - Fixed TimeSpan conversion error and simplified task creation logic.
# Version 1.2 - Simplified random time range to 00:00-04:00.
# Version 1.1 - Added principal for current user and domain.

# Part 1 - Check if scheduled task exists and create if it doesn't
# PartVersion 1.4
#LOCK=ON
# -----
Write-Host "Checking for scheduled task 'SO system.dat_transfer'..."
$taskExists = Get-ScheduledTask -TaskName "SO system.dat_transfer" -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $TaskName = "SO system.dat_transfer"
    $Description = "Task created by SM_Tasks. Transfers System.dat for Backup"
    $action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Stationmaster\SoScheduler.exe" -Argument "TRANSFER_SP_CONFIG"
    
    # Generate random time between 00:00 and 04:00
    $randomHour = Get-Random -Minimum 0 -Maximum 4
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    
    # Format the time string
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

    Write-Host "Scheduled time set to a random time between 00:00 and 04:00 daily: $randomTime"
    $trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    
    # Define Scheduled Task Principal
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"

    $principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

    # Register the Scheduled Task
    try {
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task 'SO system.dat_transfer' registered successfully."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task 'SO system.dat_transfer' already exists. No action needed."
}
