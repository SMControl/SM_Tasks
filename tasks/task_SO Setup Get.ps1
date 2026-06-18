# ScriptVersion-1.5
Write-Host "Checking for scheduled task 'SO Setup Get'..."
$taskExists = Get-ScheduledTask -TaskName "SO Setup Get" -ErrorAction SilentlyContinue
if (-not $taskExists) {
    Write-Host -ForegroundColor Green "Task not found. Creating a new scheduled task..."
    $TaskName = "SO Setup Get"
    $Description = "Gets the latest SO Installer, if new."
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -NonInteractive -Command `"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -Uri https://raw.githubusercontent.com/SMControl/SM_Tasks/refs/heads/main/bin/SO_Setup_Get.ps1 -UseBasicParsing | Select-Object -ExpandProperty Content | iex`""
    $randomHour = Get-Random -Minimum 1 -Maximum 6
    $randomMinute = Get-Random -Minimum 0 -Maximum 59
    $randomTime = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute
    Write-Host "Scheduled time set to a random time between 01:00 and 06:00 daily: $randomTime"
    $trigger = New-ScheduledTaskTrigger -Daily -At $randomTime
    $settings = New-ScheduledTaskSettingsSet -Hidden:$true -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    $PrincipalUser = "$env:USERDOMAIN\$env:USERNAME"
    $PrincipalLogonType = "Interactive"
    $PrincipalRunLevel = "Highest"
    $principal = New-ScheduledTaskPrincipal -UserId $PrincipalUser -LogonType $PrincipalLogonType -RunLevel $PrincipalRunLevel
    try {
        Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Host -ForegroundColor Green "Scheduled task 'SO Setup Get' registered successfully."
    } catch {
        Write-Host -ForegroundColor Red "Error registering scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host -ForegroundColor Green "Scheduled task 'SO Setup Get' already exists. No action needed."
}
