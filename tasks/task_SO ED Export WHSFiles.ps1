Write-Host "task_SO ED Export WHSFiles.ps1 - Version 1.3"
# ScriptVersion-1.3
# Checks for and creates a scheduled task to run SOScheduler.exe with the EDBULLETINS argument every 5 minutes, 24 hours a day, using an XML definition for high compatibility.
# Recent Changes
# Version 1.3 - Complete rewrite to use schtasks.exe with an embedded XML definition (Task Definition Language) to ensure repetition works on older/incompatible PowerShell versions.

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
    
    # Part 2 - Define XML Task Definition (TDL) for High Compatibility
    # This XML defines the task, action, settings, and crucially, the 5-minute repetition
    # PartVersion 1.3
    #LOCK=OFF
    # -----
    $TaskXML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$Description</Description>
    <Author>$PrincipalUser</Author>
    <Date>$((Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'))</Date>
    <URI>\$TaskName</URI>
  </RegistrationInfo>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT30M</ExecutionTimeLimit>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
    <AllowDemandStart>true</AllowDemandStart>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
  </Settings>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2000-01-01T00:00:00</StartBoundary>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>PT5M</Interval>
        <Duration>P1D</Duration>
      </Repetition>
      <Enabled>true</Enabled>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$PrincipalUser</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>Highest</RunLevel>
    </Principal>
  </Principals>
  <Actions Context="Author">
    <Exec>
      <Command>$ActionExecute</Command>
      <Arguments>$ActionArgument</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    # Part 3 - Register the Scheduled Task via XML File
    # PartVersion 1.3
    #LOCK=OFF
    # -----
    # Create a temporary file path
    $tempXmlPath = [System.IO.Path]::GetTempFileName() + ".xml"
    
    try {
        # Save the XML to the temporary file
        $TaskXML | Out-File -FilePath $tempXmlPath -Encoding UTF8 -Force
        
        Write-Host "Scheduled time set to repeat every 5 minutes for 24 hours, starting daily at 00:00 AM."

        # Register the task using schtasks.exe and the XML file
        $result = schtasks.exe /create /tn "$TaskName" /xml "$tempXmlPath" /f
        
        if ($result -match "SUCCESS") {
            Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully via XML definition."
        }
        else {
            Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName' via XML definition."
            Write-Host -ForegroundColor Red "schtasks.exe output: $result"
        }
    }
    catch {
        Write-Host -ForegroundColor Red "Error during XML creation or registration: $($_.Exception.Message)"
    }
    finally {
        # Clean up the temporary XML file
        if (Test-Path $tempXmlPath) {
            Remove-Item $tempXmlPath -Force
        }
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' already exists. No action needed."
}
