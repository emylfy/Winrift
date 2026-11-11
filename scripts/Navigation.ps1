# Shared product navigation. Opening a route never applies a configuration.
function Show-WinriftMainMenu {
    Invoke-MenuLoop -Title ('Winrift ' + (($script:AppVersion -split '\.')[0..1] -join '.')) -Items @(
        '1 › Update Windows & Drivers          ›',
        '2 › Set Up Windows                    ›',
        '3 › Install Your Apps                 ›',
        '4 › Configure Your Apps               ›',
        '---',
        '5 › Save / Restore Setup              ›',
        '6 › Undo Changes                      ›',
        '7 › Help                              ›',
        '---',
        '0 › Exit'
    ) -Actions @{
        '1' = { Show-WinriftSetupStages -StartAt 1 }
        '2' = { Show-WinriftSetupStages -StartAt 2 }
        '3' = { Show-WinriftSetupStages -StartAt 3 }
        '4' = { Show-WinriftSetupStages -StartAt 4 }
        '5' = { Show-WinriftSaveRestore }
        '6' = { Show-WinriftUndo }
        '7' = { Show-WinriftHelp }
    } -ExitKey '0' -HideKeys -HideHint -FocusedDescriptions @{
        1 = 'Review Windows settings before applying.'
        5 = 'Save settings and apps, or restore a saved setup.'
        6 = 'Review recorded changes and available backups.'
    }
}

function Show-WinriftSetupStages {
    param([int]$StartAt)

    for ($stage = $StartAt; $stage -le 4; $stage++) {
        $result = switch ($stage) {
            1 { Show-WinriftUpdates }
            2 { Show-WinriftSetup }
            3 { & "$script:Root\modules\apps\Apps.ps1" }
            4 { Show-WinriftAppConfiguration }
        }
        if ($result -notcontains 'Next') { return }
    }
}

function Test-WinriftIntelComponent {
    # Intel CPU alone is insufficient: inspect present display/network devices.
    try {
        return [bool](Get-PnpDevice -PresentOnly -ErrorAction Stop | Where-Object {
            $_.Class -in @('Display', 'Net', 'Bluetooth') -and $_.InstanceId -match '^PCI\\VEN_8086&|^USB\\VID_8087&'
        } | Select-Object -First 1)
    } catch { return $false }
}

function Show-WinriftUpdates {
    $items = @('1 › Open Windows Update ↗')
    $actions = @{
        '1' = {
            if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Open ms-settings:windowsupdate' -Quiet; return }
            try {
                Start-Process 'ms-settings:windowsupdate' -ErrorAction Stop
            } catch {
                Write-Log "Could not open Windows Update: $($_.Exception.Message)" -Level ERROR
                Wait-ForUser
            }
        }
        '2' = {
            $choice = Show-InteractiveMenu -Title 'Intel Driver & Support Assistant' -Items @(
                'Opens the installed Intel assistant, or offers its installation.',
                '---', 'Y › Continue', 'N › Back'
            )
            if ($choice -ne 'Y') { return }
            if ($env:WINRIFT_DRY_RUN -eq '1') { Write-Log '[DRY-RUN] Intel Driver & Support Assistant'; Wait-ForUser; return }
            $installed = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object DisplayName -Like '*Intel*Driver*Support Assistant*'
            if ($installed) { Start-Process 'https://www.intel.com/content/www/us/en/support/detect.html' }
            else {
                $offer = Show-InteractiveMenu -Title 'Install Intel Driver & Support Assistant' -Items @('Y › Install', 'N › Back')
                if ($offer -eq 'Y') { Install-WingetPackage 'Intel.IntelDriverAndSupportAssistant' 'Intel Driver & Support Assistant' | Out-Null }
            }
        }
    }
    if (Test-WinriftIntelComponent) { $items += '2 › Intel Driver & Support Assistant' }
    $items += @('---', '3 › Continue to Windows Setup        ›')
    Invoke-MenuLoop -Title 'Update Windows & Drivers' -Items $items -Actions $actions -ExitKey '0' -NextKey '3' -HideKeys -Descriptions @{
        0 = @('Install available updates and restart if prompted.')
    }
}

function Show-WinriftSetup {
    Invoke-MenuLoop -Title 'Set Up Windows' -Items @(
        '1 › Performance Tweaks               ›',
        '2 › Privacy & Debloat                ›',
        '3 › Windows Preferences              ›',
        '4 › Additional Tools                 ›',
        '---', '5 › Continue to App Installation     ›'
    ) -Actions @{
        '1' = { & "$script:Root\modules\system\Tweaks.ps1" }
        '2' = { Show-WinriftPrivacy }
        '3' = { Show-WinriftPreferences }
        '4' = { Show-WinriftTools }
    } -ExitKey '0' -NextKey '5' -HideKeys -FocusedDescriptions @{
        0 = 'Review system, graphics and power settings.'
        1 = 'Review privacy settings and app update controls.'
        3 = 'DNS, disk cleanup and your tool collections.'
    }
}

function Show-WinriftPrivacy {
    Invoke-MenuLoop -Title 'Privacy & Debloat' -Items @(
        '1 › Privacy Setup                    ›',
        '3 › App Auto-Updates                 ›',
        '---', '0 › Back'
    ) -Actions @{
        '1' = { & "$script:Root\modules\security\Privacy.ps1" }
        '3' = { . "$script:Root\modules\security\Privacy.ps1"; Show-WinriftAppUpdates }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftPreferences {
    . "$script:Root\modules\customize\Customize.Windows.ps1"
    Invoke-MenuLoop -Title 'Windows Preferences' -Items @(
        '1 › Date & Time Format               ›',
        '2 › Recent Files & Frequent Folders  ›', '---', '0 › Back'
    ) -Actions @{ '1' = { Set-ShortDateHours }; '2' = { Disable-QuickAccess } } -ExitKey '0' -HideKeys
}

function Show-WinriftTools {
    . "$script:Root\modules\security\DnsBenchmark.ps1"
    . "$script:Root\modules\system\Tweaks.Cleanup.ps1"
    . "$PSScriptRoot\ToolCollections.ps1"

    while ($true) {
        $items = @('1 › DNS Benchmark ›', '2 › Free Up Disk Space ›', '---')
        $paths = @()
        $directory = Join-Path (Get-WinriftStateRoot) 'tool-collections'
        foreach ($file in (Get-ChildItem -LiteralPath $directory -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object Name)) {
            try {
                $saved = Read-WinriftJson $file.FullName -AsHashtable
                $catalog = ConvertTo-WinriftToolCollection $saved.catalog
                $paths += $file.FullName
                $items += "$($paths.Count + 2) › $($catalog.name) ›"
            } catch {
                Write-Log "Could not read tool collection $($file.Name): $($_.Exception.Message)" -Level WARNING -Quiet
            }
        }
        $items += @('A › Add a Tool Collection… ›', '---', '0 › Back')
        $choice = Show-InteractiveMenu -Title 'Additional Tools' -Items $items -HideKeys
        try {
            switch ($choice) {
                '1' { Invoke-DnsBenchmark }
                '2' { Clear-SystemSpace }
                'A' { Show-WinriftAddToolCollection }
                { $_ -match '^[1-9][0-9]*$' -and [int]$_ -gt 2 } { Show-WinriftToolCollection $paths[[int]$choice - 3] }
                default { return }
            }
        } catch {
            Show-InfoBox -Title 'Additional Tools' -Items @($_.Exception.Message)
            Wait-ForUser
        }
    }
}

function Show-WinriftAppConfiguration {
    . "$script:Root\modules\customize\Customize.Menu.ps1"
    . "$script:Root\modules\customize\AppConfiguration.ps1"
    Invoke-MenuLoop -Title 'Configure Your Apps' -Items @(
        '1 › Terminal & PowerShell            ›',
        '2 › Code Editors                     ›',
        '3 › Desktop Tools                    ›',
        '4 › Browser Privacy                  ›',
        '5 › Organize Start Menu Shortcuts    ›'
    ) -Actions @{
        '1' = { Show-TerminalMenu }
        '2' = { Show-VSCodeConfigMenu }
        '3' = { Show-WinriftDesktop }
        '4' = { Show-WinriftBrowser }
        '5' = { Expand-StartFolders }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftDesktop {
    Invoke-MenuLoop -Title 'Desktop Tools' -Items @(
        '1 › GlazeWM                          ›', '2 › Wallpaper Collections            ↗', '---', '0 › Back'
    ) -Actions @{ '1' = { Show-WinriftGlazeWM }; '2' = { Open-WallpaperBrowser } } -ExitKey '0' -HideKeys
}

function Show-WinriftBrowser {
    Invoke-MenuLoop -Title 'Browser Privacy' -Items @(
        '1 › Run JustTheBrowser               ↗', '2 › About JustTheBrowser', '---', '0 › Back'
    ) -Actions @{
        '1' = { & "$script:Root\modules\security\JustTheBrowser.ps1" }
        '2' = { Show-InfoBox 'JustTheBrowser' @('External browser privacy tool with its own interface.', 'Review its operations before applying changes. External changes are not covered by Winrift Undo.'); Wait-ForUser }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftSaveRestore {
    . "$script:Root\modules\customize\Customize.Profile.ps1"
    Invoke-MenuLoop -Title 'Save / Restore Setup' -Items @(
        '1 › Save Setup                       ›', '2 › Restore Setup                    ›',
        '3 › Create Windows Installation Media ›', '---', '0 › Back'
    ) -Actions @{
        '1' = { Export-WinriftProfile }
        '2' = { Import-WinriftProfile }
        '3' = { & "$script:Root\modules\iso\ISOBuilder.ps1" }
    } -ExitKey '0' -HideKeys
}

function Show-WinriftUndo {
    . "$script:Root\modules\customize\Customize.Configs.ps1"
    Invoke-MenuLoop -Title 'Undo Changes' -Items @(
        '1 › Action History                   ›', '2 › Restore Configuration Backup     ›', '---', '0 › Back'
    ) -Actions @{ '1' = { Show-WinriftActionHistory }; '2' = { Restore-ConfigBackup } } -ExitKey '0' -HideKeys
}

function Show-WinriftHelp {
    Invoke-MenuLoop -Title 'Help' -Items @(
        '1 › Check for Winrift Updates', '2 › Open Logs', '3 › About', '4 › Documentation                    ↗', '5 › Uninstall                        ›', '---', '0 › Back'
    ) -Actions @{
        '1' = {
            try {
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$($versionInfo.repo)/releases/latest" -Headers @{ 'User-Agent' = 'Winrift' } -TimeoutSec 10 -ErrorAction Stop
                $tag = $release.tag_name -replace '^v', ''
                if ($tag -eq $script:AppVersion) { Write-Log 'You are running the latest published release.' }
                else { Write-Log "Published release: $tag. Local version: $script:AppVersion. Local development files will not be overwritten." }
            } catch { Write-Log "Update check unavailable: $($_.Exception.Message)" -Level WARNING }
            Wait-ForUser
        }
        '2' = { Start-Process explorer.exe -ArgumentList ('"' + (Join-Path $env:LOCALAPPDATA 'Winrift\logs') + '"') }
        '3' = { Show-InfoBox 'Winrift' @("Version $script:AppVersion", 'Windows setup utility. Review each operation before applying.', 'Registry writes alone do not demonstrate a performance benefit.'); Wait-ForUser }
        '4' = { Start-Process 'https://github.com/emylfy/Winrift/wiki' }
        '5' = { & "$script:Root\scripts\uninstall.ps1"; Wait-ForUser }
    } -ExitKey '0' -HideKeys
}