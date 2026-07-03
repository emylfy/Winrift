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
        ohmyposh  = @{ SourceDir = "$cc\cli";     Files = @("zen.toml");                         Target = "$env:USERPROFILE\.config\ohmyposh"; TargetNames = $null;             Name = "Oh My Posh" }
        fastfetch = @{ SourceDir = "$cc\cli";     Files = @("fastfetch.txt", "fastfetch.jsonc"); Target = "$env:USERPROFILE\.config\fastfetch"; TargetNames = @("fastfetch.txt", "config.jsonc"); Name = "FastFetch" }
        glazewm   = @{ SourceDir = "$cc\glazewm"; Files = @("config.yaml");                       Target = "$env:USERPROFILE\.glzr\glazewm"; TargetNames = $null;                Name = "GlazeWM" }
        vscode    = @{ SourceDir = "$cc\vscode";  Files = @("settings.json");                     Target = "$env:USERPROFILE\AppData\Roaming\Code\User"; TargetNames = $null;    Name = "VSCode" }
    }
}

function Read-WinriftProfile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Profile not found: $Path" }
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } catch {
        throw "Profile is not valid JSON: $($_.Exception.Message)"
    }
}

function Invoke-WinriftProfileApply {
    # Applies every section of a profile object non-interactively. Honours
    # $env:WINRIFT_DRY_RUN (writes nothing, logs what it would do).
    param([Parameter(Mandatory)]$ProfileObject)

    $dry = $env:WINRIFT_DRY_RUN -eq '1'
    $tweaks  = @($ProfileObject.tweaks)  | Where-Object { $_ }
    $apps    = @($ProfileObject.apps)    | Where-Object { $_ }
    $configs = @($ProfileObject.configs) | Where-Object { $_ }

    Write-Log -Message "Applying profile$(if ($ProfileObject.name) { " '$($ProfileObject.name)'" })..." -Level INFO

    if ($tweaks.Count -gt 0) {
        Write-Log -Message "Tweaks: applying $($tweaks.Count) value(s)..." -Level INFO
        if (-not $dry) { New-SafeRestorePoint }
        $n = Invoke-DesiredStateApply -Entries $tweaks
        Save-TweakBackup
        Save-DesiredState
        Write-Log -Message "Tweaks applied ($n)." -Level SUCCESS
    }

    if ($ProfileObject.privacy) {
        Write-Log -Message "Privacy: hardening..." -Level INFO
        Invoke-PrivacyHardening
    }

    if ($apps.Count -gt 0) {
        Write-Log -Message "Apps: installing $($apps.Count) package(s) via winget..." -Level INFO
        foreach ($id in $apps) {
            if ($dry) { Write-Log -Message "[DRY-RUN] winget install $id" -Level INFO; continue }
            Install-WingetPackage -PackageId $id -Name $id | Out-Null
        }
    }

    if ($configs.Count -gt 0) {
        $map = Get-WinriftConfigMap
        Write-Log -Message "Configs: applying $($configs.Count) set(s)..." -Level INFO
        foreach ($c in $configs) {
            $key = "$c".ToLower()
            if (-not $map.ContainsKey($key)) { Write-Log -Message "Unknown config set '$c' — skipped." -Level WARNING; continue }
            $m = $map[$key]
            if ($dry) { Write-Log -Message "[DRY-RUN] copy config '$key' -> $($m.Target)" -Level INFO; continue }
            $params = @{ SourceDir = $m.SourceDir; FileNames = $m.Files; TargetDir = $m.Target; ConfigName = $m.Name }
            if ($m.TargetNames) { $params.TargetFileNames = $m.TargetNames }
            Copy-ConfigFiles @params
        }
    }

    Write-Log -Message "Profile apply complete." -Level SUCCESS
    if (-not $dry) { Write-Log -Message "A restart is recommended for all changes to take effect." -Level INFO }
}
