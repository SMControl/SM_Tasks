Write-Host "task_SO WHS DOWNLOAD.ps1 - Version 1.0"
# ScriptVersion-1.0
# Checks for and creates a scheduled task to run SOScheduler.exe with the WHSDOWNLOAD argument at a random time between 02:00 AM and 04:00 AM daily.

# Part 1 - Check if scheduled task exists and create if it doesn't
# PartVersion 1.0
#LOCK=OFF
# -----
$TaskName = "SO WHS DOWNLOAD"

Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $Description = "Executes the SOScheduler WHSDOWNLOAD argument for daily data transfer."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "WHSDOWNLOAD"

    # Define Scheduled Task Principal (Uses current interactive user context)
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"

    # Part 2 - Define Action, Trigger, and Settings
    # PartVersion 1.0
    #LOCK=OFF
    # -----
    $action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
    
    # Generate random time between 02:00 and 04:00 (Hours 2, 3, and 4)
    # The -Maximum parameter for Get-Random is exclusive for the upper bound.
    $randomHour = Get-Random -Minimum 2 -Maximum 5
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    
    # Format the time string
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

    Write-Host "Scheduled time set to a random time between 02:00 and 04:00 daily: $randomTime"
    
    $trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
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
