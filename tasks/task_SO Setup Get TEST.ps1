# SO Setup Get Task Script Version 1.6
# Creates a scheduled task to run the SO_Setup_Get.ps1 script from a remote URL.
# Recent Changes
# Version 1.6 - Added ExecutionTimeLimit and iwr Timeout to prevent indefinite hangs.
# Version 1.5 - Changed Principal to SYSTEM for background execution; added Start-In directory.
# Version 1.4 - Updated -Argument to include -NoProfile and -NonInteractive.

# Part 1 - Check if scheduled task exists and create/update
# PartVersion 1.6
# -----

Write-Host "--------------------------------------------------"
Write-Host " SO Setup Get Task Setup - Version 1.6"
Write-Host "--------------------------------------------------"

$TaskName = "SO Setup Get TEST"
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Cyan "Task not found. Preparing new scheduled task..."

    # Define task parameters
    $Description = "Gets the latest SO Installer, if new."
    
    # -TimeoutSec 60 ensures the web request fails fast if GitHub is unreachable
    $Argument = "-ExecutionPolicy Bypass -NoProfile -NonInteractive -WindowStyle Hidden -Command ""& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr https://raw.githubusercontent.com/SMControl/SM_Tasks/refs/heads/main/bin/SO_Setup_Get.ps1 -UseBasicParsing -TimeoutSec 60 | iex }"""
    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument
    
    # Generate random time between 01:00 and 06:00
    $randomHour = Get-Random -Minimum 1 -Maximum 6
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute

    $trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
    
    # Settings: Kill the task if it runs longer than 30 minutes
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -Hidden:$true `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
        -DeleteExpiredTaskAfter (New-TimeSpan -Seconds 0)
    
    # Use SYSTEM account for reliable background execution
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Register the Scheduled Task
    try {
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        
        $results = @(
            [PSCustomObject]@{Property="Task Name"; Value=$TaskName},
            [PSCustomObject]@{Property="Scheduled Time"; Value=$randomTime},
            [PSCustomObject]@{Property="User Context"; Value="SYSTEM"},
            [PSCustomObject]@{Property="Time Limit"; Value="30 Minutes"},
            [PSCustomObject]@{Property="Status"; Value="Success"}
        )
        
        Write-Host ""
        $results | Format-Table -AutoSize
        Write-Host -ForegroundColor Green "Scheduled task registered successfully."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Yellow "Scheduled task '$TaskName' already exists. No action needed."
}
