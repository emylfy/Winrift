# Standalone online entry point; compatible with Windows PowerShell 5.1.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Test-WinriftLauncherCache {
    param([string]$Path)
    foreach ($file in @('Winrift.ps1', 'scripts\Main.ps1', 'scripts\Common.ps1', 'config\version.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $file) -PathType Leaf)) { return $false }
    }
    try {
        $version = Get-Content -LiteralPath (Join-Path $Path 'config\version.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        return [bool]($version.version -match '^\d+\.\d+(\.\d+)?$')
    } catch { return $false }
}

function Update-WinriftLauncherCache {
    param(
        [string]$CacheRoot,
        [string]$Repository = 'emylfy/winrift',
        [ValidateSet('stable', 'main')][string]$Channel = 'stable'
    )

    $CacheRoot = [IO.Path]::GetFullPath($CacheRoot)
    [IO.Directory]::CreateDirectory($CacheRoot) | Out-Null
    $current = Join-Path $CacheRoot ('winrift-' + $Channel)
    $stage = Join-Path $CacheRoot ('.download-' + [guid]::NewGuid().ToString('N'))
    $previous = Join-Path $CacheRoot ('.previous-' + [guid]::NewGuid().ToString('N'))
    $lock = $null
    try {
        # Prevent two launchers from swapping the same directory concurrently.
        $deadline = [DateTime]::UtcNow.AddSeconds(10)
        while (-not $lock) {
            try { $lock = [IO.File]::Open((Join-Path $CacheRoot '.update.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
            catch [IO.IOException] {
                if ([DateTime]::UtcNow -ge $deadline) { throw 'Another Winrift launcher is updating the cache. Try again shortly.' }
                Start-Sleep -Milliseconds 100
            }
        }
        $usable = Test-WinriftLauncherCache $current
        $revisionFile = Join-Path $current '.winrift-revision'
        try {
            $headers = @{
                'User-Agent' = 'Winrift'; Accept = 'application/vnd.github+json'; 'Cache-Control' = 'no-cache'
            }
            $ref = 'main'
            if ($Channel -eq 'stable') {
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                if ($release.draft -or $release.prerelease -or $release.tag_name -notmatch '^v[0-9]+\.[0-9]+(\.[0-9]+)?$') {
                    throw 'GitHub did not return a supported stable release.'
                }
                $ref = $release.tag_name
            }
            # Resolve tags (including annotated tags) to a commit before downloading.
            $remote = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/commits/$ref" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
            $revision = [string]$remote.sha
            if ($revision -notmatch '^[0-9a-f]{40}$') { throw 'GitHub returned an invalid commit ID.' }
        } catch {
            if (-not $usable) { throw }
            Write-Warning "Could not check for updates; using cached Winrift. $($_.Exception.Message)"
            return $current
        }
        if ($usable -and (Test-Path -LiteralPath $revisionFile) -and
            (Get-Content -LiteralPath $revisionFile -Raw -ErrorAction Stop).Trim() -eq $revision) {
            Write-Host "Winrift ($Channel) is up to date." -ForegroundColor Green
            return $current
        }

        try {
            [IO.Directory]::CreateDirectory($stage) | Out-Null
            $archive = Join-Path $stage 'winrift.zip'
            # Pin the archive to the checked commit, even if the selected ref moves.
            $url = "https://github.com/$Repository/archive/$revision.zip"
            Write-Host 'Downloading Winrift...' -ForegroundColor Cyan
            try { Start-BitsTransfer -Source $url -Destination $archive -DisplayName 'Winrift' -ErrorAction Stop }
            catch { Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop }
            Expand-Archive -LiteralPath $archive -DestinationPath $stage -ErrorAction Stop
            $candidate = Join-Path $stage ('winrift-' + $revision)
            if (-not (Test-WinriftLauncherCache $candidate)) { throw 'The downloaded Winrift installation is incomplete.' }
            # Parse every script before replacing a working cache.
            foreach ($file in (Get-ChildItem -LiteralPath $candidate -Recurse -File -Include *.ps1,*.psm1,*.psd1)) {
                # PS7 scripts cannot be parsed by the inbox PS5.1 launcher.
                if ($PSVersionTable.PSVersion.Major -lt 7 -and $file.Name -notin @('Winrift.ps1', 'Start-Winrift.ps1', 'RequirePwsh.ps1', 'launch.ps1')) { continue }
                $parseErrors = $null
                [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$parseErrors)
                if ($parseErrors) { throw "Invalid downloaded script: $($file.Name): $($parseErrors[0].Message)" }
            }
            [IO.File]::WriteAllText((Join-Path $candidate '.winrift-revision'), $revision)
            if (Test-Path -LiteralPath $current) { Move-Item -LiteralPath $current -Destination $previous -ErrorAction Stop }
            try { Move-Item -LiteralPath $candidate -Destination $current -ErrorAction Stop }
            catch {
                if (Test-Path -LiteralPath $previous) { Move-Item -LiteralPath $previous -Destination $current -ErrorAction Stop }
                throw
            }
            Write-Host 'Winrift cache updated.' -ForegroundColor Green
        } catch {
            if (-not (Test-WinriftLauncherCache $current)) { throw }
            Write-Warning "Update failed; using the working cached Winrift. $($_.Exception.Message)"
        }
        return $current
    } finally {
        # Only remove our own temporary siblings; retain the backup if promotion failed.
        foreach ($temporary in @($stage, $previous)) {
            $resolved = [IO.Path]::GetFullPath($temporary)
            if ((Split-Path $resolved -Parent) -ne $CacheRoot -or
                (Split-Path $resolved -Leaf) -notmatch '^\.(download|previous)-[0-9a-f]{32}$') { continue }
            if ($temporary -eq $previous -and -not (Test-WinriftLauncherCache $current)) { continue }
            if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue }
        }
        if ($lock) { $lock.Dispose() }
    }
}

$Host.UI.RawUI.WindowTitle = 'Winrift Launcher'
try {
    $channel = if ($env:WINRIFT_CHANNEL) { $env:WINRIFT_CHANNEL } else { 'stable' }
    $extractPath = Update-WinriftLauncherCache -CacheRoot (Join-Path $env:TEMP 'winrift') -Channel $channel
} catch {
    Write-Host "Winrift download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Download manually from https://github.com/emylfy/winrift' -ForegroundColor Yellow
    return
}

# Use the same diagnostic entry point as Winrift.cmd.
$shellPath = (Get-Process -Id $PID -ErrorAction Stop).Path
$entryPoint = Join-Path $extractPath 'scripts\Start-Winrift.ps1'
# Older published revisions predate the diagnostic wrapper and remain usable offline.
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) { $entryPoint = Join-Path $extractPath 'Winrift.ps1' }
& $shellPath -NoProfile -ExecutionPolicy Bypass -File $entryPoint
