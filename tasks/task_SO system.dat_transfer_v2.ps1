# task_SO system.dat_transfer.ps1 - Script v1.01
# Part 1 - Main Logic
# PartVersion-1.01
# -----
# Student note: We announce the script version and define task names.
# Legacy task name to clean up if it exists on this machine:
$OldTaskName = "SO system.dat_transfer"
# New task name to register:
$NewTaskName = "SO system.dat_transfer_v2"

Write-Host "task_SO system.dat_transfer ScriptVersion-2.0"
Write-Host "Checking for scheduled tasks..."

# Check if old or new task already exists
$oldTaskExists = Get-ScheduledTask -TaskName $OldTaskName -ErrorAction SilentlyContinue
$newTaskExists = Get-ScheduledTask -TaskName $NewTaskName -ErrorAction SilentlyContinue

$Description = "Transfers System.dat for Backup"
$action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Stationmaster\SoScheduler.exe" -Argument "TRANSFER_SP_CONFIG"

# Pick a random minute between 0 and 59 during the 06:00 AM hour (06:00 - 07:00)
$randomHour = 6
$randomMinute = Get-Random -Minimum 0 -Maximum 60
$randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute
Write-Host "Scheduled time set to a random time between 06:00 and 07:00 daily: $randomTime"

$trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
$settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -StartWhenAvailable
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"
$principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

try {
    # If the old scheduled task exists, remove it
    if ($oldTaskExists) {
        Write-Host -ForegroundColor Yellow "Legacy task '$OldTaskName' found. Deleting it..."
        Unregister-ScheduledTask -TaskName $OldTaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Waiting 5 seconds..."
        Start-Sleep -Seconds 5
    }

    # If the new scheduled task already exists, remove it before re-creating with updated settings
    if ($newTaskExists) {
        Write-Host -ForegroundColor Yellow "Task '$NewTaskName' already exists. Re-registering with new schedule..."
        Unregister-ScheduledTask -TaskName $NewTaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Waiting 5 seconds..."
        Start-Sleep -Seconds 5
    }

    Write-Host -ForegroundColor Green "Creating scheduled task '$NewTaskName'..."
    Register-ScheduledTask -TaskName $NewTaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "Scheduled task '$NewTaskName' registered successfully."
} catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
}
