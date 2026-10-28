# task_SO Remove_OneNote_Printer.ps1 v1.00
<#
.SYNOPSIS
    Creates a standalone Windows Scheduled Task that removes any OneNote printer every 10 minutes
    without requiring any script files to remain on disk.
.DESCRIPTION
    Designed for vanilla Windows 10 and Windows 11.
    Embeds a native PowerShell one-liner directly inside the Scheduled Task Action using
    Remove-Printer with wildcards ('*OneNote*', '*One Note*') so no external .ps1 file is needed.
    Runs silently every 10 minutes under NT AUTHORITY\SYSTEM with Highest Privileges.
.PARAMETER Unregister
    Removes the scheduled task from Windows Task Scheduler.
#>
[CmdletBinding()]
param(
    [switch]$Unregister
)

# ==============================================================================
# Part 1: Configuration & Task Definition [PartVersion 1.00]
# ==============================================================================
# Stop execution immediately if an unexpected error occurs so our 'catch' block can handle it.
$ErrorActionPreference = 'Stop'

# Name and description of the Scheduled Task as it will appear in Windows Task Scheduler.
$TaskName        = 'SO Remove_OneNote_Printer'
$TaskPath        = '\'
$TaskDescription = 'Checks every 10 minutes for any printer matching OneNote or One Note and removes it (scriptless inline command).'

# The inline PowerShell command stored directly inside the Scheduled Task Action.
# - Remove-Printer accepts wildcard arrays natively in Windows 10+.
# - -Confirm:$false suppresses confirmation prompts.
# - -ErrorAction SilentlyContinue ensures the task exits cleanly (code 0) when no OneNote printer exists.
$InlineCommand = "Remove-Printer -Name '*OneNote*','*One Note*' -Confirm:`$false -ErrorAction SilentlyContinue"

# Full argument string passed to powershell.exe when Task Scheduler triggers the task.
$TaskArguments = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$InlineCommand`""

# ==============================================================================
# Part 2: UI Terminal Messaging & Privilege Helpers [PartVersion 1.00]
# ==============================================================================
function Write-UiMessage {
    <#
    .SYNOPSIS
        Prints a color-coded status message to the console using Ger's Global Hex Standards.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Success', 'Warning', 'Error')][string]$Level = 'Success'
    )

    # ASCII 27 escape character used to format 24-bit TrueColor ANSI terminal output.
    $Esc   = [char]27
    $Reset = "$Esc[0m"

    switch ($Level) {
        'Error'   { $ColorCode = "$Esc[38;2;255;102;102m"; $Fallback = 'Red'    } # #ff6666 Light Red
        'Warning' { $ColorCode = "$Esc[38;2;255;204;0m";   $Fallback = 'Yellow' } # #ffcc00 Light Yellow
        'Success' { $ColorCode = "$Esc[38;2;102;255;102m"; $Fallback = 'Green'  } # #66ff66 Light Green
    }

    try {
        Write-Host "$ColorCode$Message$Reset"
    }
    catch {
        Write-Host $Message -ForegroundColor $Fallback
    }
}

function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Returns $true if the current PowerShell window is running as Administrator.
    #>
    $Identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ==============================================================================
# Part 3: Standalone Scheduled Task Registration [PartVersion 1.00]
# ==============================================================================
try {
    # Verify the script is running with Administrator rights before touching SYSTEM tasks.
    if (-not (Test-IsAdministrator)) {
        Write-UiMessage -Message "[ERROR] Administrator privileges are required. Please right-click PowerShell and select 'Run as Administrator'." -Level 'Error'
        exit 1
    }

    # Handle removal if the -Unregister switch was passed.
    if ($Unregister) {
        Write-UiMessage -Message "[PENDING] Checking for existing Scheduled Task '$TaskName'..." -Level 'Warning'
        $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($null -ne $ExistingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Write-UiMessage -Message "[OK] Unregistered Scheduled Task '$TaskName'." -Level 'Success'
        }
        else {
            Write-UiMessage -Message "[WARN] Scheduled Task '$TaskName' does not exist on this system." -Level 'Warning'
        }
        exit 0
    }

    Write-UiMessage -Message "[PENDING] Building standalone Scheduled Task '$TaskName' (every 10 minutes as SYSTEM)..." -Level 'Warning'

    # 1. Action: Run built-in Windows PowerShell with our inline one-liner (no external script file needed).
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $TaskArguments

    # 2. Trigger: Start immediately and repeat every 10 minutes indefinitely.
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Minutes 10) `
        -RepetitionDuration ([TimeSpan]::MaxValue)

    # 3. Principal: Run as NT AUTHORITY\SYSTEM with Highest Privileges so it runs silently for all users.
    $Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest

    # 4. Settings: Allow running on laptop batteries, catch up if a schedule was missed, and timeout after 2 minutes.
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

    # Register (or overwrite) the task in Windows Task Scheduler.
    Register-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -Description $TaskDescription `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Force | Out-Null

    Write-UiMessage -Message "[OK] Registered standalone Scheduled Task '$TaskName' (no script on disk required)." -Level 'Success'

    # Trigger the task immediately to clean up any OneNote printer currently present.
    Start-ScheduledTask -TaskName $TaskName
    Write-UiMessage -Message "[OK] Triggered immediate first run of '$TaskName'." -Level 'Success'
}
catch {
    Write-UiMessage -Message "[ERROR] Failed to register Scheduled Task '$TaskName': $($_.Exception.Message)" -Level 'Error'
    exit 1
}

