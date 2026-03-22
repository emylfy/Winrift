. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Show-PrivacySexyMenu {
    $Host.UI.RawUI.WindowTitle = "Privacy.sexy Launcher"
    $tool = Get-ToolConfig "privacysexy"
    Invoke-MenuLoop -Title "Privacy.sexy - Privacy & Security Hardening" -Items @(
        "[1] Build your own batch from privacy.sexy website",
        "[2] Execute latest standard preset (for most users)",
        "[R] Review project source",
        "---",
        "[3] Back to menu"
    ) -Actions @{
        "1" = { Start-Process $tool.docs }
        "2" = {
            Invoke-Tool "privacysexy" -OnSuccess { param($path) Start-Process cmd -ArgumentList "/c `"$path`"" -Wait }
            Read-Host "Press Enter to continue"
        }
        "R" = { Start-Process $tool.docs }
    } -ExitKey "3" -OnExit { & "$PSScriptRoot\SecurityMenu.ps1" }
}

Show-PrivacySexyMenu
