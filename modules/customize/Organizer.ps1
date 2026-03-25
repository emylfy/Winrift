. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName "organizer"

$Host.UI.RawUI.WindowTitle = "Organizer"

$targetPaths = @(
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
)

$excludeRegex = "^(Windows|Microsoft|Steam|Accessibility|Accessories)$"

$excludeList = @(
    "Accentcolorizer",
    "CapCut",
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

function Test-IsExcluded {
    param(
        [string]$BaseName,
        [string]$Name
    )
    if ($excludeHash.Contains($Name) -or $excludeHash.Contains($BaseName) -or $BaseName -like "Uninstall*") {
        return $true
    }
    foreach ($term in $excludeList) {
        if ($BaseName -like "*$term*") { return $true }
    }
    return $false
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and
    (Test-Path -Path $targetPaths[1])) {
    Write-Log -Message "Administrator rights required for system directory!" -Level ERROR

    $adminLaunchPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\scripts\AdminLaunch.ps1"
    . $adminLaunchPath

    Start-AdminProcess -ScriptPath $PSCommandPath
    exit
}

try {
    $dirsToBackup = $targetPaths | Where-Object { Test-Path $_ }
    if ($dirsToBackup) {
        Write-Log -Message "Creating backup to: $backupPath" -Level INFO
        Compress-Archive -Path $dirsToBackup -DestinationPath $backupPath -CompressionLevel Fastest

        if (Test-Path $backupPath) {
            Write-Log -Message "Backup successful. Size: $('{0:N2} MB' -f ((Get-Item $backupPath).Length/1MB))" -Level SUCCESS
            Write-Log -Message "Press Enter to continue" -Level INFO
            $null = Read-Host
        }
        else {
            Write-Log -Message "Backup failed! Aborting operation." -Level ERROR
            exit
        }
    }
}
catch {
    Write-Log -Message "Backup error: $_" -Level ERROR
    exit
}

foreach ($targetDir in $targetPaths) {
    if (-not (Test-Path -Path $targetDir)) {
        Write-Log -Message "Skipping missing directory: $targetDir" -Level WARNING
        continue
    }

    Write-Log -Message "Processing directory: $targetDir" -Level INFO

    $subFolders = Get-ChildItem -Path $targetDir -Directory | Where-Object {
        $_.Name -notmatch $excludeRegex -and
        -not $excludeHash.Contains($_.Name)
    }

    foreach ($folder in $subFolders) {
        $folderName = $folder.Name
        $folderFullPath = $folder.FullName

        $files = Get-ChildItem -Path $folderFullPath -File -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { -not (Test-IsExcluded -BaseName $_.BaseName -Name $_.Name) }

        if (-not $files) {
            Write-Log -Message "No movable files in: $folderName" -Level SKIP
            continue
        }

        Write-Log -Message "Folder: $folderName" -Level INFO
        Write-Log -Message "Contains these files:" -Level INFO
        $files | ForEach-Object {
            Write-Log -Message "  - $($_.Name)" -Level INFO
        }

        do {
            $response = Read-Host "`nMove $($files.Count) files from '$folderName'? (Y/N/Q)"
            $response = $response.Trim().ToUpper()
            if ($response -eq 'Q') {
                Write-Log -Message "Operation cancelled by user." -Level WARNING
                exit
            }
        } until ($response -match '^[YN]$')

        if ($response -eq 'N') {
            Write-Log -Message "Skipping folder: $folderName" -Level SKIP
            continue
        }

        $movedCount = 0
        $errors = @()

        foreach ($file in $files) {
            try {
                $destination = Join-Path -Path $targetDir -ChildPath $file.Name
                if (Test-Path $destination) {
                    Write-Log -Message "Replacing existing: $($file.Name)" -Level WARNING
                }
                Move-Item -Path $file.FullName -Destination $targetDir -Force -ErrorAction Stop
                $movedCount++
            }
            catch {
                $errors += "Failed to move $($file.Name): $_"
            }
        }

        if ($errors.Count -gt 0) {
            Write-Log -Message "Completed with $($errors.Count) errors:" -Level ERROR
            $errors | ForEach-Object { Write-Log -Message "  $_" -Level ERROR }
        }
        else {
            Write-Log -Message "Successfully moved $movedCount files" -Level SUCCESS
        }

        try {
            $remainingItems = Get-ChildItem -Path $folderFullPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not $remainingItems) {
                Remove-Item -Path $folderFullPath -Recurse -Force -ErrorAction Stop
                Write-Log -Message "Cleaned empty folder: $folderName" -Level INFO
            }
        }
        catch {
            Write-Log -Message "Error cleaning folder: $_" -Level ERROR
        }
    }
}

Write-Log -Message "Operation completed! Backup saved to: $backupPath" -Level SUCCESS