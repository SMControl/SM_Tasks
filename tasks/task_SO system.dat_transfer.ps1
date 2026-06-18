Write-Host "task_SO system.dat_transfer ScriptVersion-1.6"
# PartVersion 1.5
#LOCK=ON
# -----
Write-Host "Checking for scheduled task 'SO system.dat_transfer'..."
$taskExists = Get-ScheduledTask -TaskName "SO system.dat_transfer" -ErrorAction SilentlyContinue

# Define task parameters
$TaskName = "SO system.dat_transfer"
$Description = "Transfers System.dat for Backup"
$action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Stationmaster\SoScheduler.exe" -Argument "TRANSFER_SP_CONFIG"

# Generate random time between 02:00 and 05:00
$randomHour = Get-Random -Minimum 2 -Maximum 5
$randomMinute = Get-Random -Minimum 0 -Maximum 60

# Format the time string
$randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

Write-Host "Scheduled time set to a random time between 02:00 and 05:00 daily: $randomTime"
$trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
$settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -StartWhenAvailable

# Define Scheduled Task Principal
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"

$principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

# Register the Scheduled Task
try {
    if ($taskExists) {
        Write-Host -ForegroundColor Yellow "Task already exists. Deleting it..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Waiting 5 seconds..."
        Start-Sleep -Seconds 5
        Write-Host -ForegroundColor Green "Creating a new scheduled task..."
    }
    else {
        Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."
    }

    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "Scheduled task 'SO system.dat_transfer' registered successfully."
}
catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
}
