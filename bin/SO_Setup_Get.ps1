Write-Host "SO_Setup_Get.ps1 - Version 1.10"
# Script Version 1.10

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

try {
    Write-Host "Checking Setup versions..." -ForegroundColor Green
    $response = Invoke-WebRequest -Uri "https://www.stationmaster.com/downloads/" -UseBasicParsing
    $exeLinks = ([regex]::Matches($response.Content, '(?i)href=["''](.*?)["'']') | ForEach-Object { $_.Groups[1].Value }) | ForEach-Object {
        if ($_ -match '^(http|https)://') { $_ }
        elseif ($_ -match '^/') { "https://www.stationmaster.com$_" }
        else { "https://www.stationmaster.com/downloads/$_" }
    } | Where-Object { $_ -match "\.exe$" }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Host "Error retrieving links: $errorMessage" -ForegroundColor Red
    exit
}

$setupLinks = $exeLinks | Where-Object { $_ -match "^https://www\.stationmaster\.com/Download/Setup\d+\.exe$" }
$sortedLinks = $setupLinks | Sort-Object { [regex]::Match($_, "Setup(\d+)\.exe").Groups[1].Value -as [int] } -Descending
$highestTwoLinks = $sortedLinks | Select-Object -First 2

$downloadDirectory = "C:\winsm\SmartOffice_Installer"
if (-not (Test-Path $downloadDirectory)) {
    Write-Host "Download directory not found. Creating..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $downloadDirectory | Out-Null
}

foreach ($downloadLink in $highestTwoLinks) {
    $originalFilename = $downloadLink.Split('/')[-1]
    $destinationPath = Join-Path -Path $downloadDirectory -ChildPath $originalFilename

    try {
        $request = [System.Net.HttpWebRequest]::Create($downloadLink)
        $request.Method = "HEAD"
        $request.UserAgent = "Mozilla/5.0"
        $response = $request.GetResponse()
        $contentLength = $response.ContentLength
        $response.Close()
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error checking server for ${originalFilename}: $errorMessage" -ForegroundColor Red
        exit
    }

    $existingFiles = Get-ChildItem -Path $downloadDirectory -Filter "*.exe"
    $fileExists = $existingFiles | Where-Object { $_.Length -eq $contentLength }

    if (-not $fileExists) {
        Write-Host "Downloading: $originalFilename" -ForegroundColor Green
        try {
            Invoke-WebRequest -Uri $downloadLink -OutFile $destinationPath -UseBasicParsing
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Host "Error downloading ${originalFilename}: $errorMessage" -ForegroundColor Red
        }
    }
    else {
        Write-Host "$originalFilename already up to date." -ForegroundColor Yellow
    }
}

$downloadedFiles = Get-ChildItem -Path $downloadDirectory -Filter "*.exe" | Sort-Object LastWriteTime -Descending
if ($downloadedFiles.Count -gt 2) {
    $filesToDelete = $downloadedFiles | Select-Object -Skip 2
    foreach ($file in $filesToDelete) {
        Write-Host "Deleting old file: $($file.Name)" -ForegroundColor Red
        Remove-Item -Path $file.FullName -Force
    }
}
else {
    #     Write-Host "No old installers to delete." -ForegroundColor Green
}

# Logical Part 4: Cleanup scheduled task and old executable
# PartVersion 1.02
#LOCK=OFF
try {
    if (Get-ScheduledTask -TaskName "SO InstallerUpdates" -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName "SO InstallerUpdates" -Confirm:$false
    }
}
catch {
    # Error message for scheduled task removal is suppressed
}

try {
    if (Test-Path "C:\winsm\SO_UC.exe") {
        Remove-Item -Path "C:\winsm\SO_UC.exe" -Force
    }
}
catch {
    # Error message for file deletion is suppressed
}
exit
