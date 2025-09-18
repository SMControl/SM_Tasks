# SO Setup Get Task Script Version 1.4
# Creates a scheduled task to run the SO_Setup_Get.ps1 script from a remote URL at a random time between 01:00 AM and 06:00 AM daily.
# Recent Changes
# Version 1.4 - Updated -Argument to include -NoProfile and -NonInteractive.
# Version 1.3 - Added -NonInteractive and -NoProfile to the scheduled task argument for more robust execution.
# Version 1.2 - Added -ExecutionPolicy Bypass -Command to the scheduled task argument.
# Version 1.1 - Changed random time range to 01:00-06:00.
# Version 1.0 - Initial script creation.

# Part 1 - Check if scheduled task exists and create if it doesn't
# PartVersion 1.4
#LOCK=OFF
# -----
Write-Host "Checking for scheduled task 'SO Setup Get'..."
$taskExists = Get-ScheduledTask -TaskName "SO Setup Get" -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $TaskName = "SO Setup Get"
    $Description = "Task created by SM_Tasks. Checks for newer versions of the SO Installer Setup exe and obtains if new."
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -NonInteractive -Command irm https://raw.githubusercontent.com/SMControl/SM_Tasks/refs/heads/main/bin/SO_Setup_Get.ps1 | iex"
    
    # Generate random time between 01:00 and 06:00
    $randomHour = Get-Random -Minimum 1 -Maximum 6
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    
    # Format the time string
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

    Write-Host "Scheduled time set to a random time between 01:00 and 06:00 daily: $randomTime"
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
        Write-Host -ForegroundColor Green "Scheduled task 'SO Setup Get' registered successfully."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task 'SO Setup Get' already exists. No action needed."
}
