. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "unigetui"

function Show-InstallPrompt {
    $choice = Show-InteractiveMenu -Title "UniGetUI" -Items @(
        "A package manager UI for Windows that lets you",
        "discover, install, and update apps using winget,",
        "Chocolatey, and other sources.",
        "---",
        "1 › Install UniGetUI",
        "2 › Back to menu"
    )

    if ($choice -eq "1") { Install-UniGetUI }
}

function Install-UniGetUI {
    Clear-Host
    Write-Log -Message "Checking UniGetUI installation..." -Level INFO

    $installed = Install-WingetPackage "Devolutions.UniGetUI" "UniGetUI"

    if ($installed) {
        Write-Log -Message "Launching UniGetUI..." -Level INFO
        Start-Process "unigetui:"
    } else {
        Write-Log -Message "UniGetUI could not be installed via winget. Opening website for manual download..." -Level ERROR
        Start-Process "https://www.marticliment.com/unigetui/"
    }
    Wait-ForUser
}

function Get-InstalledAndBrokenIds {
    # Runs winget list once and returns two HashSets: installed IDs and broken IDs.
    # "Broken" = winget reports the package but version is "Unknown" (partial install).
    $output = & winget list --accept-source-agreements --disable-interactivity 2>&1
    $installed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $broken    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $output) {
        if ($line -match '\b([A-Za-z0-9][\w\-.]+\.[A-Za-z0-9][\w\-.]+)\b') {
            $id = $Matches[1]
            $null = $installed.Add($id)
            if ($line -match '\bUnknown\b') { $null = $broken.Add($id) }
        }
    }
    return $installed, $broken
}

function Show-NativePackageSelector {
    param([string]$BundleName)

    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $bundlePath = Join-Path $root "config\bundles\$BundleName.ubundle"
    if (-not (Test-Path $bundlePath)) {
        Write-Log -Message "Bundle not found: $bundlePath" -Level ERROR
        Wait-ForUser
        return
    }

    $bundle = Get-Content $bundlePath -Raw | ConvertFrom-Json
    $pkgs = @($bundle.packages | Where-Object { $_.ManagerName -eq 'Winget' })
    if ($pkgs.Count -eq 0) {
        Write-Log -Message "No winget packages in this bundle." -Level WARNING
        Wait-ForUser
        return
    }

    $installedIds, $brokenIds = Invoke-WithSpinner -Message "Checking installed packages" -ScriptBlock {
        param($bundleRoot, $bundleName)
        $bp = Join-Path $bundleRoot "config\bundles\$bundleName.ubundle"
        $output = & winget list --accept-source-agreements --disable-interactivity 2>&1
        $inst = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $brk  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $output) {
            if ($line -match '\b([A-Za-z0-9][\w\-.]+\.[A-Za-z0-9][\w\-.]+)\b') {
                $id = $Matches[1]
                $null = $inst.Add($id)
                if ($line -match '\bUnknown\b') { $null = $brk.Add($id) }
            }
        }
        return $inst, $brk
    } -ArgumentList $root, $BundleName

    $installedCount = 0
    $items = @()
    foreach ($pkg in $pkgs) {
        $isBroken    = $brokenIds    -and $brokenIds.Contains($pkg.Id)
        $isInstalled = $installedIds -and $installedIds.Contains($pkg.Id)
        if ($isInstalled) { $installedCount++ }
        $suffix = if ($isBroken) { "  $Red[broken]$Reset" } elseif ($isInstalled) { "  $Dim(installed)$Reset" } else { "" }
        $items += "$($pkg.Id) › $($pkg.Name)$suffix"
    }

    $title = $BundleName
    if ($installedCount -gt 0) { $title += " · $installedCount installed" }

    $selected = Show-MultiSelect -Title $title -Items $items
    if (-not $selected -or $selected.Count -eq 0) { return }

    Write-Host ""
    foreach ($id in $selected) {
        $pkg = $pkgs | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($null -eq $pkg) { continue }
        if ($brokenIds -and $brokenIds.Contains($id)) {
            # Force-reinstall broken packages
            Write-Log -Message "Reinstalling (broken): $($pkg.Name)" -Level WARNING
            & winget install $id --force --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
            Write-Log -Message "$($pkg.Name) reinstalled." -Level SUCCESS
        } else {
            $null = Install-WingetPackage -PackageId $id -Name $pkg.Name
        }
    }
    Wait-ForUser
}

function Show-AllPackagesSearch {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $bundlesDir = Join-Path $root "config\bundles"
    $bundleFiles = Get-ChildItem $bundlesDir -Filter "*.ubundle" -ErrorAction SilentlyContinue

    if (-not $bundleFiles) {
        Write-Log -Message "No bundle files found in $bundlesDir" -Level ERROR
        Wait-ForUser
        return
    }

    # Build combined package list with category sections
    $allPkgs = [System.Collections.Generic.List[hashtable]]::new()
    $items   = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $bundleFiles | Sort-Object Name) {
        $catName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $bundle  = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $pkgs    = @($bundle.packages | Where-Object { $_.ManagerName -eq 'Winget' })
        if ($pkgs.Count -eq 0) { continue }

        $items.Add("--- $catName ---")
        foreach ($pkg in $pkgs) {
            $items.Add("$($pkg.Id) › $($pkg.Name)")
            $allPkgs.Add(@{ Id = $pkg.Id; Name = $pkg.Name })
        }
    }

    if ($allPkgs.Count -eq 0) {
        Write-Log -Message "No winget packages found across all bundles." -Level WARNING
        Wait-ForUser
        return
    }

    # Check installed in one pass
    $rawList = Invoke-WithSpinner -Message "Checking installed packages" -ScriptBlock {
        & winget list --accept-source-agreements --disable-interactivity 2>&1
    }
    $installedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $brokenIds    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $rawList) {
        if ($line -match '\b([A-Za-z0-9][\w\-.]+\.[A-Za-z0-9][\w\-.]+)\b') {
            $id = $Matches[1]
            $null = $installedIds.Add($id)
            if ($line -match '\bUnknown\b') { $null = $brokenIds.Add($id) }
        }
    }

    # Annotate items with installed/broken markers
    $annotated = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $items) {
        if ($item -match '^---') { $annotated.Add($item); continue }
        if ($item -match '^([^\s›>]+)') {
            $id = $Matches[1]
            $suffix = if ($brokenIds.Contains($id)) { "  $Red[broken]$Reset" } elseif ($installedIds.Contains($id)) { "  $Dim(installed)$Reset" } else { "" }
            $annotated.Add("$item$suffix")
        } else {
            $annotated.Add($item)
        }
    }

    $selected = Show-MultiSelect -Title "All Packages" -Items $annotated.ToArray()
    if (-not $selected -or $selected.Count -eq 0) { return }

    Write-Host ""
    foreach ($id in $selected) {
        $pkg = $allPkgs | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($null -eq $pkg) { continue }
        if ($brokenIds.Contains($id)) {
            Write-Log -Message "Reinstalling (broken): $($pkg.Name)" -Level WARNING
            & winget install $id --force --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
            Write-Log -Message "$($pkg.Name) reinstalled." -Level SUCCESS
        } else {
            $null = Install-WingetPackage -PackageId $id -Name $pkg.Name
        }
    }
    Wait-ForUser
}

function Get-UniGetUIExe {
    $local = "$env:LOCALAPPDATA\Programs\UniGetUI\UniGetUI.exe"
    if (Test-Path $local) { return $local }
    $cmd = Get-Command unigetui -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Show-UniGetUIBundleMenu {
    $root       = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $unigetuiExe = Get-UniGetUIExe
    $bundlesDir = Join-Path $root "config\bundles"
    $bundleFiles = Get-ChildItem $bundlesDir -Filter "*.ubundle" -ErrorAction SilentlyContinue | Sort-Object Name

    if (-not $bundleFiles) {
        Write-Log -Message "No bundle files found in $bundlesDir" -Level WARNING
        Wait-ForUser
        return
    }

    $friendlyNames = @{
        "Browsers"     = "Web Browsers"
        "CreativeMedia"= "Creative & Media"
        "Games"        = "Gaming"
    }

    $items = @()
    $i = 1
    foreach ($f in $bundleFiles) {
        $base  = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $label = if ($friendlyNames.ContainsKey($base)) { $friendlyNames[$base] } else { $base }
        $items += "$i › $label"
        $i++
    }
    $backKey = $i
    $items += "---"
    $items += "$backKey › Back"

    while ($true) {
        $choice = Show-InteractiveMenu -Title "Open Bundle in UniGetUI" -Items $items
        if ($null -eq $choice -or $choice -eq "$backKey") { return }

        $n = 0
        if (-not [int]::TryParse($choice, [ref]$n) -or $n -lt 1 -or $n -gt $bundleFiles.Count) { continue }

        $bundlePath = $bundleFiles[$n - 1].FullName
        $bundleName = [System.IO.Path]::GetFileNameWithoutExtension($bundlePath)
        Write-Log -Message "Opening $bundleName bundle in UniGetUI..." -Level INFO

        if ($unigetuiExe) {
            Start-Process -FilePath $unigetuiExe -ArgumentList "--import-bundle `"$bundlePath`""
        } else {
            Start-Process -FilePath $bundlePath
        }

        Write-Log -Message "Bundle opened — select packages in the UniGetUI window and click Install." -Level SUCCESS
        Wait-ForUser
        return
    }
}

function Show-AppCategoryMenu {
    $unigetuiExe       = Get-UniGetUIExe
    $unigetuiInstalled = $null -ne $unigetuiExe
    $unigetuiLabel     = if ($unigetuiInstalled) { "8 › UniGetUI - Open bundle in app" } else { "8 › UniGetUI - Install package manager UI" }

    Invoke-MenuLoop -Title "App Categories" -Items @(
        "0 › Search all packages",
        "---",
        "1 › Development",
        "2 › Web Browsers",
        "3 › Utilities",
        "4 › Productivity",
        "5 › Creative & Media",
        "6 › Gaming",
        "7 › Communications",
        "---",
        $unigetuiLabel,
        "---",
        "9 › Back to menu"
    ) -Actions @{
        "0" = { Show-AllPackagesSearch }
        "1" = { Show-NativePackageSelector "Development" }
        "2" = { Show-NativePackageSelector "Browsers" }
        "3" = { Show-NativePackageSelector "Utilities" }
        "4" = { Show-NativePackageSelector "Productivity" }
        "5" = { Show-NativePackageSelector "CreativeMedia" }
        "6" = { Show-NativePackageSelector "Games" }
        "7" = { Show-NativePackageSelector "Communications" }
        "8" = { if ($unigetuiInstalled) { Show-UniGetUIBundleMenu } else { Show-InstallPrompt } }
    } -ExitKey "9"
}

$Host.UI.RawUI.WindowTitle = "Winrift - App Bundles"

Show-AppCategoryMenu
