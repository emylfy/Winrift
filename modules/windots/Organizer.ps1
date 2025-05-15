. "$PSScriptRoot\..\..\scripts\Common.ps1"

$Host.UI.RawUI.WindowTitle = "Organizer"

$targetPaths = @(
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
)

$excludeRegex = "^(Windows|Microsoft|Steam|Accessibility|Accessories)$"

$excludeList = @(
    "Accentcolorizer",
    "Character Map",
    "Command Prompt",
    "Component Services",
    "Computer Management",
    "Control Panel",
    "Disk Cleanup",
    "Event Viewer",
    "Git",
    "Install Additional Tools for Node.js",
    "iSCsI Initiator",
    "Memory Diagnostics Tool",
    "Node.js",
    "ODBC Data Sources",
    "Performance Monitor",
    "postgreSQL",
    "RecoveryDrive",
    "Registry Editor",
    "Resource Monitor",
    "Uninstall",
    "Windows Powershell"
)

$backupPath = Join-Path -Path $env:USERPROFILE -ChildPath "Desktop\StartMenuBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

$excludeHash = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($item in $excludeList) {
    $null = $excludeHash.Add($item)
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and
    (Test-Path -Path $targetPaths[1])) {
    Write-Host "`nAdministrator rights required for system directory!`n" -ForegroundColor Red
    Start-Sleep 2
    if ($MyInvocation.MyCommand.Path) {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -File `"$($MyInvocation.MyCommand.Path)`""
    }
    else {
        Write-Host "Please save the script before running" -ForegroundColor Yellow
    }
    exit
}

try {
    $dirsToBackup = $targetPaths | Where-Object { Test-Path $_ }
    if ($dirsToBackup) {
        Write-Host "`nCreating backup to: $backupPath" -ForegroundColor Cyan
        Compress-Archive -Path $dirsToBackup -DestinationPath $backupPath -CompressionLevel Fastest

        if (Test-Path $backupPath) {
            Write-Host "Backup successful. Size: $('{0:N2} MB' -f ((Get-Item $backupPath).Length/1MB))" -ForegroundColor Green
            Write-Host "Press Enter to continue" -ForegroundColor DarkCyan
            $null = Read-Host
        }
        else {
            Write-Host "Backup failed! Aborting operation." -ForegroundColor Red
            exit
        }
    }
}
catch {
    Write-Host "Backup error: $_" -ForegroundColor Red
    exit
}

foreach ($targetDir in $targetPaths) {
    if (-not (Test-Path -Path $targetDir)) {
        Write-Host "`nSkipping missing directory: $targetDir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`nProcessing directory: $targetDir" -ForegroundColor Cyan

    $subFolders = Get-ChildItem -Path $targetDir -Directory | Where-Object {
        $_.Name -notmatch $excludeRegex -and
        -not $excludeHash.Contains($_.Name) -and
        -not (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | 
              Where-Object { 
                  $file = $_
                  $excludeHash.Contains($_.Name) -or 
                  $excludeHash.Contains($_.BaseName) -or
                  ($excludeList | Where-Object { $file.BaseName -like "*$_*" }) -or
                  $_.BaseName -like "Uninstall*"
              })
    }

    foreach ($folder in $subFolders) {
        $folderName = $folder.Name
        $folderFullPath = $folder.FullName

        $files = Get-ChildItem -Path $folderFullPath -File -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { 
                     $file = $_
                     -not ($excludeList | Where-Object { $file.BaseName -like "*$_*" }) -and
                     -not $excludeHash.Contains($_.Name) -and 
                     -not $excludeHash.Contains($_.BaseName) -and
                     -not ($_.BaseName -like "Uninstall*")
                 }

        if (-not $files) {
            Write-Host "`nNo movable files in: $folderName" -ForegroundColor DarkGray
            continue
        }

        Write-Host "`nFolder: $folderName" -ForegroundColor Cyan
        Write-Host "Contains these files:" -ForegroundColor White
        $files | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }

        do {
            $response = Read-Host "`nMove $($files.Count) files from '$folderName'? (Y/N/Q)"
            $response = $response.Trim().ToUpper()
            if ($response -eq 'Q') { 
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                exit 
            }
        } until ($response -match '^[YN]$')

        if ($response -eq 'N') {
            Write-Host "Skipping folder: $folderName" -ForegroundColor Yellow
            continue
        }

        $movedCount = 0
        $errors = @()
        
        foreach ($file in $files) {
            try {
                $destination = Join-Path -Path $targetDir -ChildPath $file.Name
                if (Test-Path $destination) {
                    Write-Host "Replacing existing: $($file.Name)" -ForegroundColor DarkYellow
                }
                Move-Item -Path $file.FullName -Destination $targetDir -Force -ErrorAction Stop
                $movedCount++
            }
            catch {
                $errors += "Failed to move $($file.Name): $_"
            }
        }

        if ($errors.Count -gt 0) {
            Write-Host "`nCompleted with $($errors.Count) errors:" -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
        else {
            Write-Host "`nSuccessfully moved $movedCount files" -ForegroundColor Green
        }

        try {
            $remainingItems = Get-ChildItem -Path $folderFullPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not $remainingItems) {
                Remove-Item -Path $folderFullPath -Recurse -Force -ErrorAction Stop
                Write-Host "Cleaned empty folder: $folderName" -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Host "Error cleaning folder: $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nOperation completed! Backup saved to: $backupPath`n" -ForegroundColor Green