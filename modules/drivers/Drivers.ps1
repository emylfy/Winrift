. "$PSScriptRoot\..\..\scripts\Common.ps1"

Initialize-Logging -ModuleName "drivers"

function Install-IntelDSA {
    $installed = Install-WingetPackage "Intel.IntelDriverAndSupportAssistant" "Intel Driver & Support Assistant"
    if ($installed) {
        Start-Process "https://www.intel.com/content/www/us/en/support/intel-driver-support-assistant.html"
    } else {
        Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
    }
    Start-Sleep -Seconds 2
}

function Show-DeviceMenu {
    Invoke-MenuLoop -Title "Drivers" -Items @(
        "1 › Intel Driver & Support Assistant (auto-install)",
        "---",
        "0 › Back to Menu"
    ) -Actions @{
        "1" = { Install-IntelDSA }
    } -ExitKey "0"
}

if ($MyInvocation.InvocationName -ne '.') {
    Show-DeviceMenu
}
