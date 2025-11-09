Write-Host "task_SO ED Export WHSFiles.ps1 - Version 1.5"
# ScriptVersion-1.5
# Checks for and creates a scheduled task to run SOScheduler.exe with the EDBULLETINS argument every 5 minutes, 24 hours a day, using schtasks.exe for highest compatibility.
# Recent Changes
# Version 1.5 - Corrected the /du (Duration) format in the schtasks.exe command from 24:00:00 to 24H:00m to fix the "Invalid duration value" error on legacy systems.
# Version 1.4 - Complete rewrite to use schtasks.exe command line with /ri (Repeat Interval) and /du (Duration) arguments.

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
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $LogonType = "/IT" # /IT = Interactive Token (run only when user is logged in)
    
    # Part 2 - Register the Scheduled Task using schtasks.exe
    # schtasks.exe is the most compatible way to create repetitive tasks on legacy systems.
    # Arguments:
    # /create: Create a new task
    # /tn: Task Name
    # /tr: Task Run (Executable and Arguments)
    # /sc DAILY: Schedule Daily
    # /st 00:00:00: Start Time (Midnight)
    # /ri 5: Repeat Interval (5 minutes)
    # /du 24H:00m: Duration (24 hours, in required [HHH]H:[m]m format)
    # /rl HIGHEST: Run Level (Highest)
    # /it: Interactive Only (Logon Type)
    # /f: Force (Overwrite if it exists, though we check first)
    # PartVersion 1.5
    #LOCK=OFF
    # -----
    
    Write-Host "Scheduled time set to repeat every 5 minutes for 24 hours, starting daily at 00:00:00."

    try {
        # Note the fix: /du 24H:00m
        $result = schtasks.exe /create /tn "$TaskName" /tr "`"$ActionExecute`" $ActionArgument" /sc DAILY /st 00:00:00 /ri 5 /du 24H:00m /rl HIGHEST /it /f
        
        if ($result -match "SUCCESS") {
            Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully via schtasks.exe."
        }
        else {
            Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName' via schtasks.exe."
            Write-Host -ForegroundColor Red "schtasks.exe output: $result"
        }
    }
    catch {
        Write-Host -ForegroundColor Red "Error executing schtasks.exe command: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' already exists. No action needed."
}
