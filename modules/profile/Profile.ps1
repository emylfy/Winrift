# Declarative Winrift profile: one JSON file describing a machine
# (tweaks + apps + configs + privacy) applied in a single non-interactive pass.
# Requires Common.ps1 to be dot-sourced first (for Write-Log, Set-RegistryValue,
# Install-WingetPackage, Invoke-DesiredStateApply, Save-TweakBackup/DesiredState,
# New-SafeRestorePoint). Config and privacy helpers are pulled in on demand below.

$script:WinriftRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

if (-not (Get-Command Copy-ConfigFiles -ErrorAction SilentlyContinue)) {
    . "$script:WinriftRoot\modules\customize\Customize.Configs.ps1"
}
if (-not (Get-Command Invoke-PrivacyHardening -ErrorAction SilentlyContinue)) {
    . "$script:WinriftRoot\modules\security\Privacy.ps1"
}

function Get-WinriftConfigMap {
    # Named config sets -> where their bundled default files are copied. Same
    # sources and targets the interactive Customize menu uses, but data-driven so
    # a profile can apply them headlessly.
    $cc = Join-Path $script:WinriftRoot "modules\customize\config"
    $docs = [Environment]::GetFolderPath('MyDocuments')
    return @{
        terminal  = @{ SourceDir = "$cc\cli";     Files = @("terminal.json");                   Target = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"; TargetNames = @("settings.json"); Name = "Windows Terminal" }
        pwsh      = @{ SourceDir = "$cc\cli";     Files = @("Microsoft.PowerShell_profile.ps1"); Target = "$docs\PowerShell";               TargetNames = $null;                Name = "PowerShell profile" }
        pwsh5     = @{ SourceDir = "$cc\cli"; Files = @("Microsoft.PowerShell_profile.ps1"); Target = "$docs\WindowsPowerShell"; TargetNames = $null; Name = "Windows PowerShell profile" }
        ohmyposh  = @{ SourceDir = "$cc\cli";     Files = @("zen.toml");                         Target = "$env:USERPROFILE\.config\ohmyposh"; TargetNames = $null;             Name = "Oh My Posh" }
        fastfetch = @{ SourceDir = "$cc\cli";     Files = @("fastfetch.txt", "fastfetch.jsonc"); Target = "$env:USERPROFILE\.config\fastfetch"; TargetNames = @("fastfetch.txt", "config.jsonc"); Name = "FastFetch" }
        glazewm   = @{ SourceDir = "$cc\glazewm"; Files = @("config.yaml");                       Target = "$env:USERPROFILE\.glzr\glazewm"; TargetNames = $null;                Name = "GlazeWM" }
        vscode    = @{ SourceDir = "$cc\vscode";  Files = @("settings.json");                     Target = "$env:USERPROFILE\AppData\Roaming\Code\User"; TargetNames = $null;    Name = "VSCode" }
    }
}

. "$PSScriptRoot\Setup.ps1"

function Read-WinriftProfile {
    param([Parameter(Mandatory)][string]$Path)
    Read-WinriftSetup -Path $Path
}

function Invoke-WinriftProfileApply {
    param([Parameter(Mandatory)]$ProfileObject)
    $setup=ConvertTo-WinriftSetup $ProfileObject
    foreach($note in @($setup.migrationNotes)){if($note){Write-Log $note -Level WARNING}}
    if(@($setup.migrationNotes|Where-Object{$_ -like 'Legacy privacy flag*'}).Count){throw 'Legacy privacy flag requires separate Privacy Setup review before this profile can be applied headlessly.'}
    $results=Invoke-WinriftSetupApply -Setup $setup
    foreach($result in $results){Write-Log "$($result.Action): $($result.Status)"}
    if(@($results|Where-Object{$_.Status -notin @('Applied','AlreadyMatches','Completed','DryRun')}).Count){throw 'Setup contains failed, unsupported or incomplete operations. Review individual results.'}
}