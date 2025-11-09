Write-Host "task_SO PROCESS SALES.ps1 - Version 1.0"
# ScriptVersion-1.0
# Checks for and creates a scheduled task to run SOScheduler.exe with the PROCESSSALES argument daily at 1:00 AM, 3:00 AM, and 5:00 AM.

# Part 1 - Check if scheduled task exists and define parameters
# PartVersion 1.0
#LOCK=OFF
# -----
$TaskName = "SO PROCESS SALES"

Write-Host "Checking for scheduled task '$TaskName'..."
$taskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."

    # Define task parameters
    $Description = "Executes the SOScheduler PROCESSSALES argument daily at 1am, 3am, and 5am."
    $ActionExecute = "C:\Program Files (x86)\StationMaster\SOScheduler.exe"
    $ActionArgument = "PROCESSSALES"
    
    # Define Scheduled Task Principal (Uses current interactive user context)
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"

    # Part 2 - Define Action, Triggers, and Settings
    # PartVersion 1.0
    #LOCK=OFF
    # -----
    $action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
    
    # Define the three fixed daily triggers
    $Trigger1AM = (New-ScheduledTaskTrigger -Daily -At "01:00 AM")
    $Trigger3AM = (New-ScheduledTaskTrigger -Daily -At "03:00 AM")
    $Trigger5AM = (New-ScheduledTaskTrigger -Daily -At "05:00 AM")
    
    # Combine all triggers into an array
    $Triggers = @($Trigger1AM, $Trigger3AM, $Trigger5AM)

    Write-Host "Scheduled times set to 01:00 AM, 03:00 AM, and 05:00 AM daily."

    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    $principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

    # Part 3 - Register the Scheduled Task
    # PartVersion 1.0
    #LOCK=OFF
    # -----
    try {
        # Note: The -Trigger parameter accepts an array of triggers.
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $Triggers -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully with 3 daily triggers."
    }
    catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' already exists. No action needed."
}
