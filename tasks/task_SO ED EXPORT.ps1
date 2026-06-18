Write-Host "task_SO ED EXPORT.ps1 - Version 1.1"
# ScriptVersion-1.1
# Checks for and creates a scheduled task to run SOScheduler.exe with the EDEXPORT argument at a random time between 02:00 AM and 04:00 AM daily.
# Recent Changes
# Version 1.1 - Rewritten to use schtasks.exe for high compatibility AND corrected the randomization flaw by running a PowerShell command block that calculates a new random time daily.

# Part 1 - Check if scheduled task exists and define parameters
# PartVersion 1.0
#LOCK=OFF
# -----
$TaskName = "SO ED EXPORT"

Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $Description = "Executes the SOScheduler EDEXPORT argument daily at a random time between 2am and 4am."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "EDEXPORT"
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    
    # Part 2 - Define Action using an embedded PowerShell command block
    # The command block handles the randomization every day the task runs.
    # PartVersion 1.1
    #LOCK=OFF
    # -----
    
    # PowerShell command to be executed by the scheduled task:
    # 1. Calculates a random minute (0 to 119) for the 2-hour window (2:00 AM to 4:00 AM)
    # 2. Uses the random minute to calculate the execution time (in seconds)
    # 3. Sleeps for that duration, then runs the executable.
    $RandomCommand = @(
        "$Min = Get-Random -Minimum 0 -Maximum 119;",
        "$WaitTime = $Min * 60;",
        "Start-Sleep -Seconds $WaitTime;",
        "& `"$ActionExecute`" $ActionArgument"
    ) -join ''

    $TaskCommand = "powershell.exe -WindowStyle Hidden -Command `"$RandomCommand`""

    # Part 3 - Register the Scheduled Task using schtasks.exe
    # schtasks.exe is the most compatible way to create basic daily tasks.
    # Arguments:
    # /create: Create a new task
    # /tn: Task Name
    # /tr: Task Run (The PowerShell Command)
    # /sc DAILY: Schedule Daily
    # /st 02:00:00: Start Time (fixed, the randomization happens inside the script)
    # /rl HIGHEST: Run Level (Highest)
    # /it: Interactive Only (Logon Type)
    # /f: Force (Overwrite if it exists, though we check first)
    # PartVersion 1.1
    #LOCK=OFF
    # -----
    
    Write-Host "Scheduled task set to start daily at 02:00:00 and wait a random time (0-119 minutes) before execution."

    try {
        # Register the task using schtasks.exe
        $result = schtasks.exe /create /tn "$TaskName" /tr "`"$TaskCommand`"" /sc DAILY /st 02:00:00 /rl HIGHEST /it /f
        
        if ($result -match "SUCCESS") {
            Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully via schtasks.exe."
            Write-Host -ForegroundColor Green "The task will run the command at a new random time every day."
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
