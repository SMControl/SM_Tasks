# ScriptVersion-1.0
# Checks for and creates a scheduled task to run SO_Scheduler.exe with the TRANSFER_SP_CONFIG argument at a random time between 01:10 AM and 04:30 AM daily.
# Recent Changes
# Version 1.0 - Initial script creation.

# Part 1 - Check if scheduled task exists and create if it doesn't
# PartVersion 1.0
#LOCK=ON
# -----
Write-Host "Checking for scheduled task 'SO system.dat_transfer'..."
$taskExists = Get-ScheduledTask -TaskName "SO system.dat_transfer" -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Stationmaster\SoScheduler.exe" -Argument "TRANSFER_SP_CONFIG"
    
    # Generate random time between 01:10 and 04:30
    $minMinutes = 10
    $maxMinutes = (4 * 60) + 30
    $totalMinutes = Get-Random -Minimum $minMinutes -Maximum $maxMinutes
    $randomHour = [math]::Floor($totalMinutes / 60)
    $randomMinute = $totalMinutes % 60
    
    # Format the time string
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

    Write-Host "Scheduled time set to a random time between 01:10 and 04:30 daily: $randomTime"
    $trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit "PT30M"
    $principal = New-ScheduledTaskPrincipal -RunLevel Highest

    # Register the task
    try {
        Register-ScheduledTask -TaskName "SO system.dat_transfer" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task 'SO system.dat_transfer' registered successfully."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task 'SO system.dat_transfer' already exists. No action needed."
}
