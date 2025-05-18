Write-Host "SM_Tasks.ps1 - Version 1.16"
# Part 1 - Configuration and Setup
# PartVersion-1.02
#LOCK=ON
# -----
$tempPath = "C:\winsm\temp_sm_tasks"
$githubUrl = "https://github.com/SMControl/SM_Tasks/archive/refs/heads/main.zip"
$zipFileName = "SM_Tasks.zip"
$zipFilePath = Join-Path $tempPath $zipFileName
$workingDirectory = ""

if (Test-Path $tempPath -PathType Container) {
    try {
        Write-Host "Deleting existing temporary directory: $tempPath" -ForegroundColor Cyan
        Remove-Item -Path $tempPath -Recurse -Force | Out-Null
    } catch {
        Write-Host "Error deleting existing directory: $_" -ForegroundColor Red
        Write-Error "Failed to delete existing directory. Exiting."
        exit 1
    }
}

if (-Not (Test-Path $tempPath -PathType Container)) {
    try {
        Write-Host "Creating temporary directory: $tempPath" -ForegroundColor Cyan
        New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
    } catch {
        Write-Host "Error creating directory: $_" -ForegroundColor Red
        Write-Error "Failed to create directory. Exiting."
        exit 1
    }
}

# Part 2 - Download the zip file
# PartVersion-1.00
#LOCK=ON
# -----
Write-Host "Downloading SM_Tasks from GitHub..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $githubUrl -OutFile $zipFilePath
} catch {
    Write-Host "Error downloading zip: $_" -ForegroundColor Red
    Write-Error "Failed to download zip. Exiting."
    Remove-Item -Path $tempPath -Recurse -Force
    exit 1
}

# Part 3 - Extract the zip file
# PartVersion-1.00
#LOCK=ON
# -----
Write-Host "Extracting zip..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $zipFilePath -DestinationPath $tempPath -Force
    $extractedFolders = Get-ChildItem -Path $tempPath -Directory
    if ($extractedFolders.Count -eq 1) {
        $workingDirectory = $extractedFolders[0].FullName
    }
    else {
        Write-Host "Error: Could not determine extracted folder." -ForegroundColor Red
        Write-Error "Extraction failed. Exiting."
        Remove-Item -Path $tempPath -Recurse -Force
        exit 1
    }

} catch {
    Write-Host "Error extracting zip: $_" -ForegroundColor Red
    Write-Error "Failed to extract zip. Exiting."
    Remove-Item -Path $tempPath -Recurse -Force
    exit 1
}



# Part 6 - Cross-reference tasks and scripts, and display menu
# PartVersion-1.15
#LOCK=ON
# -----
Write-Host "Creating task menu..." -ForegroundColor Cyan

# Display Menu and Get User Selection
do {
    # Part 4 - Get list of Windows scheduled tasks
    # PartVersion-1.04
    #LOCK=ON
    # -----
    Write-Host "Getting scheduled tasks..." -ForegroundColor Cyan
    try {
        $scheduledTasks = Get-ScheduledTask | Where-Object {$_.TaskName -like "SO_*"} | Select-Object -ExpandProperty TaskName
    } catch {
        Write-Host "Error getting scheduled tasks: $_" -ForegroundColor Red
        Write-Error "Failed to get scheduled tasks. Exiting."
        Remove-Item -Path $tempPath -Recurse -Force
        exit 1
    }

    # Part 5 - Get list of task scripts
    # PartVersion-1.06
    #LOCK=ON
    # -----
    Write-Host "Getting task scripts..." -ForegroundColor Cyan
    $taskScriptsPath = Join-Path $workingDirectory "tasks"
    if (-Not (Test-Path $taskScriptsPath -PathType Container)) {
        Write-Host "Error: 'tasks' folder not found." -ForegroundColor Red
        Write-Error "Failed to find task scripts. Exiting."
        Remove-Item -Path $tempPath -Recurse -Force
        exit 1
    }

    try {
        $taskScripts = Get-ChildItem -Path $taskScriptsPath
    } catch {
        Write-Host "Error getting task scripts: $_" -ForegroundColor Red
        Write-Error "Failed to get task scripts. Exiting."
        Remove-Item -Path $tempPath -Recurse -Force
        exit 1
    }
    $taskMenu = @()
    foreach ($script in $taskScripts) {
        $scriptName = ($script.Name -replace '^task_', '' -replace '\.ps1$', '')
        $taskNameMatch = $scheduledTasks -contains $scriptName
        if ($taskNameMatch) {
            $menuEntry = [PSCustomObject]@{
                Name   = $scriptName
                Color  = "Green"
                Script = $script.FullName
            }
        } else {
            $menuEntry = [PSCustomObject]@{
                Name   = $scriptName
                Color  = "Yellow"
                Script = $script.FullName
            }
        }
        $taskMenu += $menuEntry
    }
    Clear-Host
    Write-Host "Available Tasks:" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
    for ($i = 0; $i -lt $taskMenu.Count; $i++) {
        $menuItem = $taskMenu[$i]
        Write-Host "  $($i+1). $($menuItem.Name)" -ForegroundColor $menuItem.Color
    }
    Write-Host "  0. Exit" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
    $selection = Read-Host "Enter the number of the task to run: "

    if ($selection -match "^[0-9]+$") {
        $selection = [int]$selection
        if ($selection -ge 1 -and $selection -le $taskMenu.Count) {
            # Part 7 - Execute Selected Task
            # PartVersion-1.00
            #LOCK=ON
            # -----
            $selectedTask = $taskMenu[$selection - 1]
            Write-Host "Running task: $($selectedTask.Name)..." -ForegroundColor Cyan
            try {
                Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$($selectedTask.Script)""" -Wait -WindowStyle Normal
            } catch {
                Write-Host "Error running task $($selectedTask.Name): $_" -ForegroundColor Red
                Write-Error "Failed to run task. Continuing."
                Start-Sleep -Seconds 2
            }
        } elseif ($selection -eq 0) {
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
} while ($true)

# Part 8 - Cleanup
# PartVersion-1.08
#LOCK=ON
# -----
Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
try {
    if (Test-Path $tempPath)
    {
        Remove-Item -Path $tempPath -Recurse -Force
    }
    

} catch {
    Write-Host "Error cleaning up temp files: $_" -ForegroundColor Red
    Write-Error "Failed to remove temp files."
}

Write-Host "Script finished." -ForegroundColor Cyan
