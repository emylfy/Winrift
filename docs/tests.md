# Development tests

Winrift uses Pester for behavior and contract tests and PSScriptAnalyzer for static analysis. The old system performance benchmark was removed; DNS Benchmark is a separate network utility. A passing test suite does not establish performance gains or a complete Windows installation cycle.

## Run the suite on Windows

Use PowerShell 7.4+ from the repository root on a disposable Windows test machine. Some tests use temporary HKCU registry keys; the full suite is Windows-specific.

```powershell
Install-Module Pester -Scope CurrentUser -MinimumVersion 5.5.0 -Force
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force

$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Run.Exit = $true
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = './testresults.xml'
Invoke-Pester -Configuration $config
```

Run only the standalone downloader tests while changing launch behavior:

```powershell
Invoke-Pester ./tests/LauncherCache.Tests.ps1 -Output Detailed
```

The downloader tests mock network transfers and never execute downloaded scripts. They cover stable/main resolution, isolated caches, offline fallback, interrupted downloads, invalid archives, and rollback after a failed directory swap.

## Static analysis and bootstrap compatibility

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
```

CI applies the repository's configured rule exclusions and also checks enabled warning rules. The complete settings and test commands are in [the CI workflow](../.github/workflows/lint.yml).

In **Windows PowerShell 5.1**, check the bootstrap syntax without launching Winrift:

```powershell
$files = 'Winrift.ps1', 'scripts/RequirePwsh.ps1', 'scripts/Start-Winrift.ps1', 'scripts/launch.ps1', 'scripts/install.ps1'
foreach ($file in $files) {
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $PWD $file), [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
}
```

## What tests establish

| Area | Evidence | Not established by these tests |
| --- | --- | --- |
| Registry/file changes | Journaling, result verification, conflict-safe Undo | Driver behavior, reboot persistence, performance gains |
| Setup transfer | Schema checks, supported targets, file hashes, migration and restoration | Every personal file/app setting, fresh-OS recovery |
| Package queue | Partial failures and retained retries | Availability of every upstream package on every machine |
| GPU presets | Matching pinned upstream paths, types and values | Driver support, stability, FPS or latency improvement |
| ISO builder | Generated commands and embedding contracts | Bootable media and a successful installation cycle |

See [validation and known limits](validation.md) for the recorded environment, and [manual setup validation](setup.md#manual-validation) for the complete restore procedure.

## Release channels

The online launcher defaults to `stable`: it reads GitHub's latest non-prerelease release, resolves its version tag to a commit, and downloads that commit's archive. A failed update retains the previous working cache **from the same channel**. If no stable release or stable cache is available, it stops rather than using `main`.

Release assets (`launch.ps1`, `install.ps1`, and `icon.ico`) are attached by CI starting with the next release after 26.11. The README's release-asset commands become available when that release is published. Existing releases remain downloadable as source archives.

To test development explicitly in PowerShell:

```powershell
$env:WINRIFT_CHANNEL = 'main'
try {
    irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/launch.ps1 | iex
} finally {
    Remove-Item Env:WINRIFT_CHANNEL -ErrorAction SilentlyContinue
}
```

Caches are separate: `%TEMP%\winrift\winrift-stable` and `%TEMP%\winrift\winrift-main`. The old `winrift-main` cache is not promoted to stable. A downloaded checkout launched through `Winrift.cmd` runs that local copy; it is not replaced by the online launcher.

## Releasing

1. Update `config/version.json` and move completed changelog entries into the versioned release section.
2. Review the exact commit's CI results and record any manual validation separately.
3. On a push to `main`, CI publishes an untagged version only after lint and tests pass and only if `main` still points to that commit. It attaches the bootstrap assets to the release.
4. Verify the release-asset links and stable launch from a clean Windows environment. Preserve previous releases; do not move an existing tag to make a fix.

Changes to repository About/topics are GitHub settings, separate from files in this checkout.
