Write-Host "SO_DebugLogClean.ps1 - Version 2.2"
# Part 0 - Pre-Task Setup and Validation
# PartVersion-1.5
#LOCK=OFF
# -----
$CleanExePath = "C:\Program Files (x86)\StationMaster\SODebugLogClean.exe"
$CleanExeDir = Split-Path -Path $CleanExePath -Parent
$DownloadUrl = "https://github.com/SMControl/SM_Tasks/raw/refs/heads/main/bin/SODebugLogClean.exe"
if (-not (Test-Path $CleanExeDir)) {
    try {
        New-Item -ItemType Directory -Path $CleanExeDir -Force | Out-Null
    }
    catch {
        Write-Host -ForegroundColor Red "Error creating directory '$CleanExeDir': $($_.Exception.Message)"
        exit 1
    }
}
if (-not (Test-Path $CleanExePath)) {
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $CleanExePath -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "Error downloading SODebugLogClean.exe: $($_.Exception.Message)"
        exit 1
    }
}

# Part 1 - Define Task Parameters
# PartVersion-1.5
#LOCK=OFF
# -----
$TaskName = "SO DebugLogClean"
$Description = "Task created by SM_Tasks. Runs SODebugLogClean.exe daily at midnight."
$ActionExecute = $CleanExePath
$ActionArgument = ""
$TriggerDaily = (New-ScheduledTaskTrigger -Daily -At "23:59")
$PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
$PrincipalLogonType = "Interactive"
$PrincipalRunLevel = "Highest"

# Part 2 - Create Scheduled Task Action
# PartVersion-1.1
#LOCK=OFF
# -----
if ([string]::IsNullOrEmpty($ActionArgument)) {
    $Action = New-ScheduledTaskAction -Execute $ActionExecute
} else {
    $Action = New-ScheduledTaskAction -Execute $ActionExecute -Argument $ActionArgument
}

# Part 3 - Create Scheduled Task Principal
# PartVersion-1.0
#LOCK=OFF
# -----
$Principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel

# Part 4 - Register the Scheduled Task
# PartVersion-1.1
#LOCK=OFF
# -----
try {
    $Triggers = @($TriggerDaily)
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $Action -Trigger $Triggers -Principal $Principal -Force
    Write-Host -ForegroundColor Green "Scheduled task '$TaskName' registered successfully."
}
catch {
    Write-Host -ForegroundColor Red "Error registering scheduled task '$TaskName': $($_.Exception.Message)"
}
