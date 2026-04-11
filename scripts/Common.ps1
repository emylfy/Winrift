[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProgressPreference = 'SilentlyContinue'

# ANSI color palette — ported from macrift/common.sh dark theme.
# Tuned for dark terminal backgrounds (Windows Terminal, ConHost, cmd, VS Code).
$Bold   = "$([char]0x1b)[1m"
$Dim    = "$([char]0x1b)[38;5;240m"
$Reset  = "$([char]0x1b)[0m"
$Red    = "$([char]0x1b)[0;31m"
$Green  = "$([char]0x1b)[0;32m"
$Yellow = "$([char]0x1b)[0;33m"
$Cyan   = "$([char]0x1b)[38;5;39m"
$Ice    = "$([char]0x1b)[38;5;195m"

# Winget exit code for "package already installed"
$WINGET_ALREADY_INSTALLED = -1978335189

# Breadcrumb navigation stack — `$script:` is per-script-scope, so when functions
# from Common.ps1 are called from a child script (invoked via `& script.ps1`),
# the child has its own empty `$script:Breadcrumbs`. Each function defensively
# initializes it on first use within its calling scope.
$script:Breadcrumbs = [System.Collections.Generic.List[string]]::new()

function Push-Breadcrumb {
    param([string]$Name)
    if ($null -eq $script:Breadcrumbs) {
        $script:Breadcrumbs = [System.Collections.Generic.List[string]]::new()
    }
    $script:Breadcrumbs.Add($Name)
    $Host.UI.RawUI.WindowTitle = ($script:Breadcrumbs -join " $([char]0x203A) ")
}

function Pop-Breadcrumb {
    if ($null -eq $script:Breadcrumbs -or $script:Breadcrumbs.Count -eq 0) { return }
    $script:Breadcrumbs.RemoveAt($script:Breadcrumbs.Count - 1)
    if ($script:Breadcrumbs.Count -gt 0) {
        $Host.UI.RawUI.WindowTitle = ($script:Breadcrumbs -join " $([char]0x203A) ")
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','SKIP')]
        [string]$Level = 'INFO',
        [string]$LogFile = ""
    )

    $glyph = switch ($Level) {
        'SUCCESS' { "$Green$([char]0x2713)$Reset" }   # ✓
        'WARNING' { "$Yellow!$Reset" }
        'ERROR'   { "$Red$([char]0x2717)$Reset" }     # ✗
        'SKIP'    { "$Dim-$Reset" }
        default   { "$Cyan$([char]0x203A)$Reset" }    # ›
    }

    Write-Host "  $glyph  $Message"

    $effectiveLog = if ($LogFile -ne "") { $LogFile } elseif ($script:LogFile) { $script:LogFile } else { "" }
    if ($effectiveLog -ne "") {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $plainLine = "[$timestamp] [$Level] $Message"
        try {
            Add-Content -Path $effectiveLog -Value $plainLine -ErrorAction SilentlyContinue
        } catch { Write-Warning "Failed to write to log file: $($_.Exception.Message)" }
    }
}

function Wait-ForUser {
    # Suppress Read-Host's return value so callers can `Wait-ForUser; return $null`
    # without leaking an empty string into the pipeline.
    $null = Read-Host "Press Enter to continue"
}

function Invoke-WithSpinner {
    # Runs $ScriptBlock in a background runspace while animating a braille
    # spinner on the current line. Returns whatever the scriptblock outputs.
    # Throws if the scriptblock threw.
    #
    # Uses [PowerShell]::Create() instead of Start-Job — starts in ~10ms
    # (vs 200-500ms for Start-Job's child process), same isolation.
    # -ArgumentList values are passed as $args inside the scriptblock.
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [string]$Message = "Working",
        [object[]]$ArgumentList = @()
    )
    # When running under Pester (or any context that sets WINRIFT_NO_SPINNER),
    # skip the background runspace and run synchronously. Pester mocks are
    # scope-local and don't propagate into child runspaces.
    if ($env:WINRIFT_NO_SPINNER) {
        return (& $ScriptBlock @ArgumentList)
    }

    $frames = @([char]0x280B, [char]0x2819, [char]0x2839, [char]0x2838, [char]0x283C, [char]0x2834, [char]0x2826, [char]0x2827, [char]0x2807, [char]0x280F)

    $ps = [PowerShell]::Create()
    try {
        $null = $ps.AddScript($ScriptBlock)
        foreach ($arg in $ArgumentList) {
            $null = $ps.AddArgument($arg)
        }
        $handle = $ps.BeginInvoke()

        $i = 0
        while (-not $handle.IsCompleted) {
            Write-Host -NoNewline "`r$Cyan  $($frames[$i % $frames.Count])$Reset $Message..."
            Start-Sleep -Milliseconds 80
            $i++
        }
        # Clear the spinner line
        Write-Host -NoNewline ("`r" + (" " * ($Message.Length + 10)) + "`r")

        $result = $ps.EndInvoke($handle)

        # Surface errors from the background runspace as exceptions in the
        # caller so try/catch around Invoke-WithSpinner works as expected.
        if ($ps.HadErrors) {
            $errMsg = ($ps.Streams.Error | ForEach-Object { $_.Exception.Message }) -join '; '
            throw $errMsg
        }

        return $result
    } finally {
        $ps.Dispose()
    }
}

function Show-MenuBox {
    param(
        [string]$Title,
        [string[]]$Items,
        [int]$Width = 0
    )

    $h = [string][char]0x2500  # -
    $v = [string][char]0x2502  # │
    $tl = [string][char]0x256D # ╭
    $tr = [string][char]0x256E # ╮
    $bl = [string][char]0x2570 # ╰
    $br = [string][char]0x256F # ╯

    if ($Width -le 0) {
        $maxLen = $Title.Length + 2
        foreach ($item in $Items) {
            if ($item -match '^---\s+(.+?)\s*-*$') {
                $sectionLen = ("  $($Matches[1].TrimEnd('- '))").Length
                if ($sectionLen -gt $maxLen) { $maxLen = $sectionLen }
            } elseif ($item -ne "---") {
                $plainLen = ($item -replace '\x1b\[[0-9;]*m', '').Length
                if ($plainLen -gt $maxLen) { $maxLen = $plainLen }
            }
        }
        $Width = [math]::Max($maxLen + 3, 40)
    }

    # Top border with title: ╭- Title ---...---╮
    $BP = "$Bold$Dim"
    $titleText = "$h $Title "
    $topFill = $Width - $titleText.Length
    if ($topFill -lt 0) { $topFill = 0 }
    Write-Host ""
    Write-Host "$BP $tl$h $Bold$Ice$Title$BP $($h * $topFill)$tr$Reset"

    # Top padding
    Write-Host "$BP $v$Reset$(" " * $Width)$BP$v$Reset"

    foreach ($item in $Items) {
        if ($item -match '^---\s+(.+?)\s*-*$') {
            # Section header: empty line + colored text
            $sectionText = $Matches[1].TrimEnd('- ')
            Write-Host "$BP $v$Reset$(" " * $Width)$BP$v$Reset"
            $pad = $Width - ("  $sectionText").Length
            if ($pad -lt 0) { $pad = 0 }
            Write-Host "$BP $v$Reset  $Cyan$sectionText$Reset$(" " * $pad)$BP$v$Reset"
        } elseif ($item -eq "---") {
            # Plain divider: just an empty line
            Write-Host "$BP $v$Reset$(" " * $Width)$BP$v$Reset"
        } else {
            $plainItem = $item -replace '\x1b\[[0-9;]*m', ''
            $pad = ($Width - 1) - $plainItem.Length
            if ($pad -lt 0) { $pad = 0 }
            # Parse "N › text" → cyan key + dim › + default text. Otherwise pass-through.
            if ($item -match '^(\s*)([^\s]+)(\s*[›>]\s*)(.+)$') {
                $rendered = "$($Matches[1])$Cyan$($Matches[2])$Reset $Dim$([char]0x203A)$Reset $($Matches[4])"
            } else {
                $rendered = "$Dim$item$Reset"
            }
            Write-Host "$BP $v$Reset $rendered$(" " * $pad)$BP$v$Reset"
        }
    }

    # Bottom padding + border
    Write-Host "$BP $v$Reset$(" " * $Width)$BP$v$Reset"
    Write-Host "$BP $bl$($h * $Width)$br$Reset"
}

$script:RestorePointCreated = $false

function New-SafeRestorePoint {
    if ($script:RestorePointCreated) {
        Write-Log -Message "Restore point already created this session" -Level SKIP
        return
    }
    Write-Host ""
    try {
        Invoke-WithSpinner -Message "Creating System Restore Point" -ScriptBlock {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Winrift - Before System Tweaks $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop -WarningAction SilentlyContinue
        }
        Write-Log -Message "System Restore Point created successfully." -Level SUCCESS
        $script:RestorePointCreated = $true
    } catch {
        Write-Log -Message "Could not create restore point: $($_.Exception.Message)" -Level WARNING
        $script:RestorePointCreated = $true  # Don't retry — Windows blocks within 1440 min anyway
    }
    Write-Host ""
}

function Assert-AdminOrElevate {
    param(
        [string]$ScriptPath,
        [string[]]$PassthroughArgs = @()
    )
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Not running as admin. Elevating..." -ForegroundColor Yellow
        . "$PSScriptRoot\AdminLaunch.ps1"
        if (-not $ScriptPath) { $ScriptPath = (Get-PSCallStack)[1].ScriptName }
        # -NoExit so the elevated child stays open if anything crashes early.
        # -PassthroughArgs forwards CLI switches like -DryRun across the elevation hop.
        Start-AdminProcess -ScriptPath $ScriptPath -Arguments $PassthroughArgs -NoExit
        exit
    }
}

function Initialize-Logging {
    param([string]$ModuleName)
    $logDir = Join-Path $env:USERPROFILE "Winrift\logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $script:LogFile = Join-Path $logDir "${ModuleName}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
    try {
        Start-Transcript -Path $script:LogFile -Append -ErrorAction Stop | Out-Null
    } catch {
        Write-Verbose "Transcript not started: $($_.Exception.Message)"
    }
    Write-Log -Message "Session log: $script:LogFile" -Level INFO
}

function _Draw-InteractiveBox {
    # Renders a box frame seamlessly without flicker.
    # Builds the entire frame as a single string in a StringBuilder, then writes
    # it in one call wrapped in BSU (synchronized output ANSI codes), so the
    # terminal renders the new frame atomically. On non-first frames, the cursor
    # is repositioned upward by $PrevLines lines and each line ends with `e[K
    # so leftover content from a longer prior frame is cleared cleanly.
    #
    # Viewport scrolling: if the scrollable portion of the item list doesn't
    # fit on the terminal, a fixed-height viewport scrolls through the items
    # with ▲/▼ indicators showing when more is hidden. Items after the LAST
    # plain `---` divider are treated as a **pinned footer** — always visible
    # below the scroll zone (e.g. "A › Apply all", "B › Back").
    #
    # $VpTop is a [ref] tracked by the caller between frames so cursor position
    # in the pinned zone doesn't reset the scrollable viewport.
    #
    # Returns the number of terminal lines this frame occupies — caller stores
    # it and passes back as $PrevLines on the next call.
    param(
        [string]$Title,
        [string[]]$Items,
        [int]$HighlightIndex = -1,
        [bool[]]$Checked = $null,
        [int]$PrevLines = 0,
        [ref]$VpTop,
        [switch]$NoBox,
        [string]$Hint = $null,
        [switch]$HideKeys
    )

    $hasVpTop = $PSBoundParameters.ContainsKey('VpTop')

    $ESC = [char]0x1b
    $h  = [string][char]0x2500
    $v  = [string][char]0x2502
    $tl = [string][char]0x256D
    $tr = [string][char]0x256E
    $bl = [string][char]0x2570
    $br = [string][char]0x256F
    $EOL = "$ESC[K"

    # Width calculation
    $maxLen = $Title.Length + 2
    foreach ($item in $Items) {
        if ($item -match '^---\s+(.+?)\s*-*$') {
            $len = ("  $($Matches[1].TrimEnd('- '))").Length
        } elseif ($item -ne "---") {
            $len = ($item -replace '\x1b\[[0-9;]*m', '').Length + 2
            if ($Checked) { $len += 4 }
        } else { $len = 0 }
        if ($len -gt $maxLen) { $maxLen = $len }
    }
    if ($null -ne $Checked) {
        $hintLen = ("Space: toggle  A: all  Enter: confirm  Esc: cancel").Length + 2
        if ($hintLen -gt $maxLen) { $maxLen = $hintLen }
    }
    # In NoBox mode the hint may be longer than any item, so it must also
    # bound the minimum width so its inline ANSI codes don't force wrap.
    if ($NoBox -and $Hint) {
        $hLen = ($Hint -replace '\x1b\[[0-9;]*m', '').Length + 2
        if ($hLen -gt $maxLen) { $maxLen = $hLen }
    }
    $consoleW = try { [Console]::WindowWidth - 4 } catch { 100 }
    $maxAllowed = [math]::Min($consoleW, 100)
    $w = [math]::Min([math]::Max($maxLen + 3, 30), $maxAllowed)
    # Inner item content width differs between box and boxless modes:
    # box:    │ ▸ …content… │  → 5 chars of chrome (│ + space + ptr + space + │)
    # boxless:   ▸ …content…   → 2 chars of left indent, no right chrome
    if ($NoBox) {
        $itemInnerW = $w - 2
    } else {
        $itemInnerW = $w - 5
    }
    if ($null -ne $Checked) { $itemInnerW -= 4 }

    $BP = "$Bold$Dim"
    $topFill = $w - ("$h $Title ").Length
    if ($topFill -lt 0) { $topFill = 0 }

    # Pinned footer detection
    # Find the LAST plain `---` divider. Items after it are pinned footer
    # (always visible). Section-header style `--- Title ---` does not count.
    $pinnedStart = -1
    for ($i = $Items.Count - 1; $i -ge 0; $i--) {
        if ($Items[$i] -eq "---") { $pinnedStart = $i + 1; break }
    }
    if ($pinnedStart -lt 0 -or $pinnedStart -ge $Items.Count) {
        $pinnedStart = $Items.Count
        $scrollableEnd = $Items.Count
    } else {
        # The `---` divider at $pinnedStart - 1 is the separator — not rendered
        # as a row; it marks the boundary between the scroll zone and footer.
        $scrollableEnd = $pinnedStart - 1
    }
    $pinnedCount = $Items.Count - $pinnedStart

    # Count how many terminal lines a single item occupies (section headers
    # take 2: blank + colored text). We need this to compute the viewport
    # height correctly.
    $getItemHeight = {
        param($idx)
        if ($Items[$idx] -match '^---\s+') { return 2 }
        if ($Items[$idx] -match '~') { return 2 }
        return 1
    }

    # Count total scrollable rows (items can be 1 or 2 rows each)
    $scrollableRows = 0
    for ($i = 0; $i -lt $scrollableEnd; $i++) { $scrollableRows += (& $getItemHeight $i) }

    # Count pinned footer rows
    $pinnedRows = 0
    for ($i = $pinnedStart; $i -lt $Items.Count; $i++) { $pinnedRows += (& $getItemHeight $i) }

    # Viewport sizing
    # Box chrome: blank + top border + top pad + bottom pad + bottom border = 5
    #             multi-select adds hint + extra pad = +2
    # NoBox chrome: blank + title + blank + blank = 4
    #               hint row adds +2 (blank before + hint line)
    # Scroll indicators reserve 2 rows when scrolling is active
    $termHeight = try { [Console]::WindowHeight } catch { 24 }
    if ($NoBox) {
        $chrome = 4
        if ($null -ne $Checked -or $Hint) { $chrome += 2 }
    } else {
        $chrome = 5
        if ($null -ne $Checked) { $chrome += 2 }
    }
    $chrome += $pinnedRows
    $available = $termHeight - $chrome - 1  # -1 for breathing room

    $needsScroll = $scrollableRows -gt $available
    if ($needsScroll) {
        $visibleRows = [math]::Max($available - 2, 3)  # -2 for up/down rows
    } else {
        $visibleRows = $scrollableRows
    }

    # Determine vp_top (scroll position)
    $currentVp = if ($hasVpTop) { [int]$VpTop.Value } else { 0 }

    # Compute cursor row coordinates (used both for adjustment and safety check)
    $cursorRow = 0
    $cursorItemHeight = 1
    $cursorInScroll = ($HighlightIndex -ge 0 -and $HighlightIndex -lt $scrollableEnd)
    if ($cursorInScroll) {
        for ($i = 0; $i -lt $HighlightIndex; $i++) { $cursorRow += (& $getItemHeight $i) }
        $cursorItemHeight = & $getItemHeight $HighlightIndex
    }

    if ($needsScroll -and $cursorInScroll) {
        $vpTopRow = 0
        for ($i = 0; $i -lt $currentVp; $i++) { $vpTopRow += (& $getItemHeight $i) }

        if ($cursorRow -lt $vpTopRow) {
            $currentVp = $HighlightIndex
        } elseif (($cursorRow + $cursorItemHeight) -gt ($vpTopRow + $visibleRows)) {
            # Walk vp_top forward item-by-item until cursor fits
            $rowsAbove = $cursorRow + $cursorItemHeight - $visibleRows
            $currentVp = 0
            $acc = 0
            while ($currentVp -lt $HighlightIndex -and $acc -lt $rowsAbove) {
                $acc += (& $getItemHeight $currentVp)
                $currentVp++
            }
        }
    }

    # Section-header pull-back: if the item directly above $currentVp is a
    # section header, walk back to include it so the user sees the category
    # for the first visible item. Applied conditionally — only if pulling back
    # still keeps the cursor within the visible window (otherwise it would
    # push the cursor off-screen when scrolled near the bottom).
    if ($currentVp -gt 0 -and $Items[$currentVp - 1] -match '^---\s+') {
        $candidateVp = $currentVp
        while ($candidateVp -gt 0 -and $Items[$candidateVp - 1] -match '^---\s+') {
            $candidateVp--
        }
        if (-not ($needsScroll -and $cursorInScroll)) {
            # No viewport constraint, pull back freely
            $currentVp = $candidateVp
        } else {
            # Check if cursor still fits after pull-back
            $candidateVpTopRow = 0
            for ($i = 0; $i -lt $candidateVp; $i++) { $candidateVpTopRow += (& $getItemHeight $i) }
            $cursorEnd = $cursorRow + $cursorItemHeight
            if (($candidateVpTopRow + $visibleRows) -ge $cursorEnd) {
                $currentVp = $candidateVp
            }
        }
    }

    # Clamp to valid range
    if ($currentVp -lt 0) { $currentVp = 0 }
    if ($currentVp -gt $scrollableEnd) { $currentVp = $scrollableEnd }

    if ($hasVpTop) { $VpTop.Value = $currentVp }

    # Helper: build rendered lines for a single item
    # Two flavors: box mode wraps each row in │ … │ chrome with right-pad
    # to keep border alignment. NoBox mode just emits indented content.
    $buildItemLines = {
        param([int]$idx)
        $out = [System.Collections.Generic.List[string]]::new()
        $item = $Items[$idx]
        $isCur = ($idx -eq $HighlightIndex)

        if ($item -match '^---\s+(.+?)\s*-*$') {
            $sec = $Matches[1].TrimEnd('- ')
            if ($NoBox) {
                $out.Add("")
                $out.Add("  $Cyan$sec$Reset")
            } else {
                $out.Add("$BP $v$Reset$(" " * $w)$BP$v$Reset")
                $pad = $w - ("  $sec").Length; if ($pad -lt 0) { $pad = 0 }
                $out.Add("$BP $v$Reset  $Cyan$sec$Reset$(" " * $pad)$BP$v$Reset")
            }
            return $out
        }
        if ($item -eq "---") {
            if ($NoBox) {
                $out.Add("")
            } else {
                $out.Add("$BP $v$Reset$(" " * $w)$BP$v$Reset")
            }
            return $out
        }

        $displayItem = $item
        $warnText = ""
        if ($displayItem -match '^(.+?)~(.+)$') {
            $displayItem = $Matches[1].TrimEnd()
            $warnText = $Matches[2]
        }
        if ($null -ne $Checked -and $displayItem -match '^\s*[^\s]+\s*[›>]\s*(.+)$') {
            $displayItem = $Matches[1]
        }
        $plain = $displayItem -replace '\x1b\[[0-9;]*m', ''
        # When HideKeys strips the "X › " prefix, pad against the label only
        # so the right border stays aligned with non-selectable info lines.
        if ($HideKeys -and $plain -match '^(\s*)([^\s]+)\s*[›>]\s*(.+)$') {
            $plain = "$($Matches[1])$($Matches[3])"
        }

        if ($plain.Length -gt $itemInnerW) {
            $displayItem = $plain.Substring(0, [math]::Max($itemInnerW - 1, 1)) + [char]0x2026
            $plain = $displayItem
        }

        $chk = ""
        if ($null -ne $Checked) {
            $chk = if ($Checked[$idx]) { "$Green[x]$Reset " } else { "$Dim[ ]$Reset " }
            $plain = "    $plain"
        }
        $ptr = if ($isCur) { "$Bold$Ice$([char]0x25B8)$Reset " } else { "  " }
        $plainFull = "  $plain"
        $pad = ($w - 1) - $plainFull.Length; if ($pad -lt 0) { $pad = 0 }

        if ($isCur) {
            # When HideKeys is on, strip the "X › " prefix so the highlight only
            # covers the human-readable label (no bold cyan letter).
            if ($HideKeys -and $displayItem -match '^(\s*)([^\s]+)(\s*[›>]\s*)(.+)$') {
                $rendered = "$Bold$Ice$($Matches[4])$Reset"
            } else {
                $renderedItem = $displayItem -replace '(\s)>(\s)', "`$1$([char]0x203A)`$2"
                $rendered = "$Bold$Ice$renderedItem$Reset"
            }
        } elseif ($null -eq $Checked -and $displayItem -match '^(\s*)([^\s]+)(\s*[›>]\s*)(.+)$') {
            if ($HideKeys) {
                $rendered = "$($Matches[1])$($Matches[4])"
            } else {
                $rendered = "$($Matches[1])$Cyan$($Matches[2])$Reset $Dim$([char]0x203A)$Reset $($Matches[4])"
            }
        } else {
            $rendered = $displayItem
        }
        if ($NoBox) {
            $out.Add("  $ptr$chk$rendered")
        } else {
            $out.Add("$BP $v$Reset $ptr$chk$rendered$(" " * $pad)$BP$v$Reset")
        }

        # Warning line for label~warning items (always 2 rows to keep layout stable)
        if ($warnText -ne "") {
            if ($isCur) {
                $warnLine = "      $Yellow$([char]0x21) $warnText$Reset"
                $warnPlain = "      ! $warnText"
                $warnPad = [math]::Max(0, $w - 1 - $warnPlain.Length)
                if ($NoBox) {
                    $out.Add($warnLine)
                } else {
                    $out.Add("$BP $v$Reset $warnLine$(" " * $warnPad)$BP$v$Reset")
                }
            } else {
                if ($NoBox) { $out.Add("") } else { $out.Add("$BP $v$Reset$(" " * $w)$BP$v$Reset") }
            }
        }

        return $out
    }

    # Helper: build a scroll indicator row (▲/▼ ···)
    $buildScrollIndicator = {
        param([string]$direction)  # 'up' or 'down'
        $arrow = if ($direction -eq 'up') { [char]0x25B2 } else { [char]0x25BC }  # ▲ / ▼
        $label = "$arrow $([char]0x00B7)$([char]0x00B7)$([char]0x00B7)"  # "▲ ···"
        $labelLen = 5
        $leftPad = [math]::Max(0, [math]::Floor(($w - $labelLen) / 2))
        if ($NoBox) {
            return "$(" " * $leftPad)$Dim$label$Reset"
        }
        $rightPad = [math]::Max(0, $w - $labelLen - $leftPad)
        return "$BP $v$Reset$(" " * $leftPad)$Dim$label$Reset$(" " * $rightPad)$BP$v$Reset"
    }
    $buildEmptyRow = {
        if ($NoBox) { return "" }
        "$BP $v$Reset$(" " * $w)$BP$v$Reset"
    }

    # Build frame
    $lines = [System.Collections.Generic.List[string]]::new()

    $lines.Add("")
    if ($NoBox) {
        # Bold+ice title, just indented, no surrounding chrome
        $lines.Add("  $Bold$Ice$Title$Reset")
        $lines.Add("")
    } else {
        $lines.Add("$BP $tl$h $Bold$Ice$Title$BP $($h * $topFill)$tr$Reset")
        $lines.Add((& $buildEmptyRow))
    }

    # Scroll-up indicator (when scrolling is active, always reserve the row)
    if ($needsScroll) {
        if ($currentVp -gt 0) {
            $lines.Add((& $buildScrollIndicator 'up'))
        } else {
            $lines.Add((& $buildEmptyRow))
        }
    }

    # Render scrollable items within the viewport
    $rendered = 0
    $i = $currentVp
    while ($i -lt $scrollableEnd -and $rendered -lt $visibleRows) {
        $itemLines = & $buildItemLines $i
        foreach ($line in $itemLines) {
            if ($rendered -lt $visibleRows) {
                $lines.Add($line)
                $rendered++
            }
        }
        $i++
    }
    $lastRenderedScrollable = $i  # exclusive end of what we drew

    # Fill remaining viewport rows with empty lines to keep box height stable
    while ($rendered -lt $visibleRows) {
        $lines.Add((& $buildEmptyRow))
        $rendered++
    }

    # Scroll-down indicator
    if ($needsScroll) {
        if ($lastRenderedScrollable -lt $scrollableEnd) {
            $lines.Add((& $buildScrollIndicator 'down'))
        } else {
            $lines.Add((& $buildEmptyRow))
        }
    }

    # Pinned footer (always visible, after scroll zone)
    for ($i = $pinnedStart; $i -lt $Items.Count; $i++) {
        $itemLines = & $buildItemLines $i
        foreach ($line in $itemLines) { $lines.Add($line) }
    }

    $lines.Add((& $buildEmptyRow))

    # Hint line — caller-provided $Hint takes priority. Otherwise, multi-select
    # auto-generates the standard hint. NoBox mode uses indented dim text;
    # box mode wraps inside │ … │ chrome.
    $hintText = $null
    if ($Hint) {
        $hintText = $Hint
    } elseif ($null -ne $Checked) {
        $hintText = "Space: toggle  A: all  Enter: confirm  Esc: cancel"
    }
    if ($hintText) {
        if ($NoBox) {
            $lines.Add("  $Dim$hintText$Reset")
        } else {
            $hPlain = $hintText -replace '\x1b\[[0-9;]*m', ''
            $hPad = $w - $hPlain.Length - 1; if ($hPad -lt 0) { $hPad = 0 }
            $lines.Add("$BP $v$Reset $Dim$hintText$Reset$(" " * $hPad)$BP$v$Reset")
            $lines.Add((& $buildEmptyRow))
        }
    }
    if (-not $NoBox) {
        $lines.Add("$BP $bl$($h * $w)$br$Reset")
    }

    $newLines = $lines.Count

    # Assemble the frame: BSU begin + reposition + content + leftover wipe + BSU end
    $sb = [System.Text.StringBuilder]::new(2048 + ($newLines * 64))
    $null = $sb.Append("$ESC[?2026h")
    if ($PrevLines -gt 0) {
        $null = $sb.Append("$ESC[${PrevLines}A`r")
    }
    foreach ($line in $lines) {
        $null = $sb.Append($line).Append($EOL).Append("`n")
    }
    # If the new frame is shorter than the prior one, erase the leftover lines below
    if ($PrevLines -gt $newLines) {
        $extra = $PrevLines - $newLines
        for ($i = 0; $i -lt $extra; $i++) {
            $null = $sb.Append($EOL).Append("`n")
        }
    }
    $null = $sb.Append("$ESC[?2026l")

    [Console]::Write($sb.ToString())
    return $newLines
}

function Invoke-MenuLoop {
    param(
        [string]$Title,
        [string[]]$Items,
        [hashtable]$Actions,
        [string]$Prompt = " ",
        [string]$ExitKey = $null,
        [scriptblock]$OnExit = $null
    )

    # Parse selectable items
    $selectIdx = [System.Collections.Generic.List[int]]::new()
    $keyMap = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $t = $Items[$i]
        if ($t -ne "---" -and $t -notmatch '^---\s+') {
            $selectIdx.Add($i)
            if ($t -match '^\s*([^\s]+)\s*[›>]') { $keyMap[$i] = $Matches[1] }
        }
    }
    if ($selectIdx.Count -eq 0) { return }

    # Breadcrumb: push after guard so early return won't leak
    $cleanTitle = $Title -replace '\x1b\[[0-9;]*m', '' -replace ' v\d+\.\d+[^\s]*\s*$', ''
    Push-Breadcrumb $cleanTitle

    $cursor = 0
    $savedVisible = try { [Console]::CursorVisible } catch { $true }
    $savedCtrlC = [Console]::TreatControlCAsInput
    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host
    $prevLines = 0
    $vpTop = 0

    try {
        while ($true) {
            $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop)

            # Capture Ctrl+C as input only while waiting for a key — restore default
            # behavior during action dispatch so long-running ops can still be aborted.
            [Console]::TreatControlCAsInput = $true
            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            [Console]::TreatControlCAsInput = $savedCtrlC
            $vk = $k.VirtualKeyCode

            # Ctrl+C → treat as "back" (same as Escape)
            if ($k.Character -eq [char]3) {
                if ($ExitKey) { if ($OnExit) { & $OnExit }; return }
                continue
            }

            # Navigation
            if ($vk -eq 38 -and $cursor -gt 0) { $cursor--; continue }
            if ($vk -eq 40 -and $cursor -lt $selectIdx.Count - 1) { $cursor++; continue }

            # Resolve selected key
            $selKey = $null
            if ($vk -eq 13 -or $vk -eq 39) {  # Enter or Right
                $selKey = $keyMap[$selectIdx[$cursor]]
            } elseif ($vk -eq 27 -or $vk -eq 37) {  # Escape or Left
                if ($ExitKey) { if ($OnExit) { & $OnExit }; return }
                continue
            } else {
                $ch = $k.Character
                if ($ch -and $ch -ne "`0") { $selKey = [string]$ch }
            }
            if (-not $selKey) { continue }

            # Check exit
            if ($ExitKey -and ($selKey -eq $ExitKey -or $selKey.ToUpper() -eq $ExitKey.ToUpper())) {
                if ($OnExit) { & $OnExit }
                return
            }

            # Execute action
            $actionKey = $null
            if ($Actions.ContainsKey($selKey)) { $actionKey = $selKey }
            elseif ($Actions.ContainsKey($selKey.ToUpper())) { $actionKey = $selKey.ToUpper() }
            if ($actionKey) {
                try { [Console]::CursorVisible = $true } catch {}
                & $Actions[$actionKey]
                try { [Console]::CursorVisible = $false } catch {}
                # Action ran arbitrary output — frame anchor is lost, restart from top
                Clear-Host
                $prevLines = 0
                $vpTop = 0
                # Snap cursor to selected item
                for ($j = 0; $j -lt $selectIdx.Count; $j++) {
                    if ($keyMap[$selectIdx[$j]] -eq $actionKey) { $cursor = $j; break }
                }
            }
        }
    } finally {
        Pop-Breadcrumb
        [Console]::TreatControlCAsInput = $savedCtrlC
        try { [Console]::CursorVisible = $savedVisible } catch {}
    }
}

function Show-InteractiveMenu {
    # Single-shot arrow-navigable menu. Drop-in replacement for the
    # Show-MenuBox + Read-Host pattern. Returns the selected key
    # (the token before the › separator) or $null on Escape/Left.
    #
    # -NoClear: skip the initial Clear-Host so callers can print prose
    # (description, evidence, etc.) above the menu without losing it.
    # The cursor reposition between frames only walks back box-height lines,
    # leaving anything above the box position untouched.
    param(
        [string]$Title,
        [string[]]$Items,
        [switch]$NoClear,
        [switch]$HideKeys
    )

    $selectIdx = [System.Collections.Generic.List[int]]::new()
    $keyMap = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $t = $Items[$i]
        if ($t -ne "---" -and $t -notmatch '^---\s+') {
            if ($t -match '^\s*([^\s]+)\s*[›>]') {
                $selectIdx.Add($i)
                $keyMap[$i] = $Matches[1]
            }
        }
    }
    if ($selectIdx.Count -eq 0) { return $null }

    $cursor = 0
    $savedVisible = try { [Console]::CursorVisible } catch { $true }
    $savedCtrlC = [Console]::TreatControlCAsInput
    try { [Console]::CursorVisible = $false } catch {}
    if (-not $NoClear) { Clear-Host }
    $prevLines = 0
    $vpTop = 0

    # Auto-confirm: if NO_CONFIRM=1 and menu has "Y ›" item — return "Y" without rendering
    if ($env:WINRIFT_NO_CONFIRM -eq "1") {
        $yItem = $Items | Where-Object { $_ -match '^\s*Y\s*[›>]' } | Select-Object -First 1
        if ($yItem) { return "Y" }
    }

    try {
        while ($true) {
            if ($HideKeys) {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -HideKeys
            } else {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop)
            }

            [Console]::TreatControlCAsInput = $true
            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            [Console]::TreatControlCAsInput = $savedCtrlC
            $vk = $k.VirtualKeyCode

            # Ctrl+C → cancel (same as Esc)
            if ($k.Character -eq [char]3) { return $null }

            if ($vk -eq 38) {  # Up
                if ($cursor -gt 0) { $cursor-- } else { $cursor = $selectIdx.Count - 1 }
                continue
            }
            if ($vk -eq 40) {  # Down
                if ($cursor -lt $selectIdx.Count - 1) { $cursor++ } else { $cursor = 0 }
                continue
            }

            if ($vk -eq 13 -or $vk -eq 39) {  # Enter or Right
                return $keyMap[$selectIdx[$cursor]]
            }
            if ($vk -eq 27 -or $vk -eq 37) {  # Escape or Left
                return $null
            }

            $ch = $k.Character
            if ($ch -and $ch -ne "`0") {
                $typed = ([string]$ch).ToUpper()
                foreach ($idx in $selectIdx) {
                    if ($keyMap[$idx] -and $keyMap[$idx].ToUpper() -eq $typed) {
                        return $keyMap[$idx]
                    }
                }
            }
        }
    } finally {
        [Console]::TreatControlCAsInput = $savedCtrlC
        try { [Console]::CursorVisible = $savedVisible } catch {}
    }
}

function Show-MultiSelect {
    param(
        [string]$Title,
        [string[]]$Items,
        [bool[]]$Defaults = $null,
        [switch]$NoBox
    )

    $selectIdx = [System.Collections.Generic.List[int]]::new()
    $checked = [bool[]]::new($Items.Count)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        if ($Items[$i] -ne "---" -and $Items[$i] -notmatch '^---\s+') {
            $selectIdx.Add($i)
            if ($Defaults -and $i -lt $Defaults.Count) { $checked[$i] = $Defaults[$i] }
        }
    }
    if ($selectIdx.Count -eq 0) { return @() }

    $cursor = 0
    $savedVisible = try { [Console]::CursorVisible } catch { $true }
    $savedCtrlC = [Console]::TreatControlCAsInput
    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host
    $prevLines = 0
    $vpTop = 0

    try {
        while ($true) {
            if ($NoBox) {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -Checked $checked -PrevLines $prevLines -VpTop ([ref]$vpTop) -NoBox
            } else {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -Checked $checked -PrevLines $prevLines -VpTop ([ref]$vpTop)
            }

            [Console]::TreatControlCAsInput = $true
            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            [Console]::TreatControlCAsInput = $savedCtrlC
            $vk = $k.VirtualKeyCode
            $ch = $k.Character

            # Ctrl+C → cancel
            if ($ch -eq [char]3) { return @() }

            if ($vk -eq 38 -and $cursor -gt 0) { $cursor--; continue }
            if ($vk -eq 40 -and $cursor -lt $selectIdx.Count - 1) { $cursor++; continue }

            if ($vk -eq 32) {  # Space — toggle
                $checked[$selectIdx[$cursor]] = -not $checked[$selectIdx[$cursor]]
                continue
            }

            if ($ch -eq 'a' -or $ch -eq 'A') {  # Toggle all
                $allOn = ($selectIdx | ForEach-Object { $checked[$_] }) -notcontains $false
                foreach ($si in $selectIdx) { $checked[$si] = -not $allOn }
                continue
            }

            if ($vk -eq 13) {  # Enter — confirm
                $result = @()
                foreach ($si in $selectIdx) {
                    if ($checked[$si]) {
                        if ($Items[$si] -match '^\s*([^\s]+)\s*[›>]') { $result += $Matches[1] }
                        else { $result += $si.ToString() }
                    }
                }
                return $result
            }

            if ($vk -eq 27) { return @() }  # Escape — cancel
        }
    } finally {
        [Console]::TreatControlCAsInput = $savedCtrlC
        try { [Console]::CursorVisible = $savedVisible } catch {}
    }
}

$script:AuditQueue = [System.Collections.Generic.List[hashtable]]::new()

function Add-AuditEntry {
    param([string]$Path, [string]$Name, [string]$Type, $Value, [string]$Message)
    $current = $null
    try {
        $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $prop -and $null -ne $prop.$Name) { $current = $prop.$Name }
    } catch {}
    $script:AuditQueue.Add(@{
        Path = $Path; Name = $Name; Type = $Type; Value = $Value
        Message = $Message; Current = $current
    })
}

function Show-AuditTable {
    if ($script:AuditQueue.Count -eq 0) {
        Write-Log -Message "No changes to preview." -Level INFO
        return $false
    }
    $changed = @($script:AuditQueue | Where-Object { "$($_.Current)" -ne "$($_.Value)" })
    $skipped = $script:AuditQueue.Count - $changed.Count
    if ($changed.Count -eq 0) {
        Write-Log -Message "All values already match. Nothing to apply." -Level INFO
        $script:AuditQueue.Clear()
        return $false
    }

    $items = @()
    foreach ($e in $changed) {
        $cur = if ($null -eq $e.Current) { "(not set)" } else { "$($e.Current)" }
        $new = "$($e.Value)"
        $items += "$($e.Message)  $Dim$cur$Reset $Yellow->$Reset $Green$new$Reset"
    }
    if ($skipped -gt 0) { $items += "---"; $items += "$Dim$skipped value(s) already match — skipped$Reset" }
    $items += "---"
    $items += "$($changed.Count) change(s) to apply"
    $items += "---"
    $items += "Y › Apply changes"
    $items += "N › Cancel"

    $choice = Show-InteractiveMenu -Title "Review Changes" -HideKeys -Items $items
    return ($choice -eq "Y")
}

function Invoke-AuditedApply {
    $changed = @($script:AuditQueue | Where-Object { "$($_.Current)" -ne "$($_.Value)" })
    foreach ($e in $changed) {
        Set-RegistryValue -Path $e.Path -Name $e.Name -Type $e.Type -Value $e.Value -Message $e.Message
    }
    $script:AuditQueue.Clear()
}

function Clear-AuditQueue {
    $script:AuditQueue.Clear()
}

$script:TweakBackupEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateEntries = [System.Collections.Generic.List[hashtable]]::new()
$script:DesiredStateCategory = "Uncategorized"
$_baseDir = $env:USERPROFILE
if (-not $_baseDir) { $_baseDir = $env:HOME }
if (-not $_baseDir) { $_baseDir = [System.IO.Path]::GetTempPath() }
$script:TweakBackupDir = Join-Path $_baseDir "Winrift\tweaks"
$script:DesiredStateDir = Join-Path $_baseDir "Winrift\tweaks"

function Start-TweakSession {
    # Don't clear if entries already accumulated this session
    $script:DesiredStateCategory = "Uncategorized"
}

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Type,
        $Value,
        [string]$Message
    )

    if ($script:CollectMode) {
        Add-AuditEntry -Path $Path -Name $Name -Type $Type -Value $Value -Message $Message
        return
    }

    if ($env:WINRIFT_DRY_RUN -eq "1") {
        Write-Log -Message "[DRY-RUN] $Message" -Level INFO
        return
    }

    try {
        # Capture previous value for rollback
        $existed = Test-Path $Path
        $prevValue = $null
        $prevType = $null
        if ($existed) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $prop -and $null -ne $prop.$Name) {
                $prevValue = $prop.$Name
                $prevType = (Get-Item $Path).GetValueKind($Name).ToString()
            }
        }
        $script:TweakBackupEntries.Add(@{
            Path      = $Path
            Name      = $Name
            PrevValue = $prevValue
            PrevType  = $prevType
            Existed   = ($null -ne $prevValue)
        })

        if (-not $existed) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop

        $written = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
        if ($null -eq $written) {
            Write-Log -Message "Failed to verify $Name at $Path - value not found after write" -Level ERROR
        } else {
            $script:DesiredStateEntries.Add(@{
                Path     = $Path
                Name     = $Name
                Value    = $Value
                Type     = $Type
                Category = $script:DesiredStateCategory
            })
            Write-Log -Message $Message -Level SUCCESS
        }
    }
    catch {
        Write-Log -Message "Failed to set $Name at $Path. Error: $_" -Level ERROR
    }
}

function Save-TweakBackup {
    if ($script:TweakBackupEntries.Count -eq 0) { return $null }
    [System.IO.Directory]::CreateDirectory($script:TweakBackupDir) | Out-Null
    $backup = @{
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        entries   = @($script:TweakBackupEntries)
    }
    $fileName = "backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $filePath = Join-Path $script:TweakBackupDir $fileName
    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Tweak backup saved: $filePath ($($script:TweakBackupEntries.Count) entries)" -Level SUCCESS
}

function Save-DesiredState {
    if ($script:DesiredStateEntries.Count -eq 0) { return }
    [System.IO.Directory]::CreateDirectory($script:DesiredStateDir) | Out-Null
    $filePath = Join-Path $script:DesiredStateDir "desired_state.json"

    $existing = @()
    if (Test-Path $filePath) {
        try {
            $json = Get-Content $filePath -Raw | ConvertFrom-Json
            if ($json.entries) { $existing = @($json.entries) }
        } catch {
            Write-Log -Message "Could not read existing desired state, starting fresh." -Level WARNING
        }
    }

    $lookup = [ordered]@{}
    foreach ($entry in $existing) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = $entry
    }

    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    foreach ($entry in $script:DesiredStateEntries) {
        $key = "$($entry.Path)|$($entry.Name)"
        $lookup[$key] = @{
            Path      = $entry.Path
            Name      = $entry.Name
            Value     = $entry.Value
            Type      = $entry.Type
            Category  = $entry.Category
            UpdatedAt = $now
        }
    }

    $state = @{
        version     = 1
        lastUpdated = $now
        entries     = @($lookup.Values)
    }
    $state | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
    Write-Log -Message "Desired state updated: $filePath ($($lookup.Count) total entries)" -Level SUCCESS
}

function Restore-TweakBackup {
    if (-not (Test-Path $script:TweakBackupDir)) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $backups = Get-ChildItem -Path $script:TweakBackupDir -Filter "backup_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-Log -Message "No tweak backups found." -Level INFO
        Wait-ForUser
        return
    }

    $menuItems = @()
    for ($i = 0; $i -lt [math]::Min($backups.Count, 10); $i++) {
        $b = Get-Content $backups[$i].FullName -Raw | ConvertFrom-Json
        $count = $b.entries.Count
        $menuItems += "$($i + 1) › $($b.timestamp) ($count changes)"
    }
    $cancelIdx = [math]::Min($backups.Count, 10) + 1
    $menuItems += "---"
    $menuItems += "$cancelIdx › Cancel"

    $choice = Show-InteractiveMenu -Title "Restore Tweak Backup" -Items $menuItems
    if ($null -eq $choice -or $choice -eq "$cancelIdx") { return }

    $idx = 0
    if (-not ([int]::TryParse($choice, [ref]$idx)) -or $idx -lt 1 -or $idx -gt $backups.Count) { return }

    $selected = Get-Content $backups[$idx - 1].FullName -Raw | ConvertFrom-Json
    $restored = 0
    $errors = 0

    foreach ($entry in $selected.entries) {
        try {
            if ($entry.Existed -and $null -ne $entry.PrevValue) {
                $type = if ($entry.PrevType) { $entry.PrevType } else { "String" }
                Set-ItemProperty -Path $entry.Path -Name $entry.Name -Type $type -Value $entry.PrevValue -Force
                $restored++
            } elseif (-not $entry.Existed) {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                $restored++
            }
        } catch {
            $errors++
        }
    }

    Write-Log -Message "Restored $restored of $($selected.entries.Count) registry values. Errors: $errors" -Level $(if ($errors -eq 0) { 'SUCCESS' } else { 'WARNING' })
    Write-Log -Message "A system restart is recommended for changes to take effect." -Level INFO
    Wait-ForUser
}

function Get-ToolConfig {
    param([string]$ToolId)
    $toolsFile = Join-Path $PSScriptRoot "..\config\tools.json"
    if (-not (Test-Path $toolsFile)) {
        Write-Log -Message "tools.json not found at $toolsFile" -Level ERROR
        return $null
    }
    $config = Get-Content $toolsFile -Raw | ConvertFrom-Json
    return $config.tools | Where-Object { $_.id -eq $ToolId }
}

function Invoke-SecureScript {
    param(
        [string]$Url,
        [string]$ToolName = "script",
        [string]$ExpectedHash = ""
    )

    $scriptContent = Invoke-WithSpinner -Message "Downloading $ToolName" -ScriptBlock {
        param($u)
        Invoke-RestMethod -Uri $u -TimeoutSec 60 -ErrorAction Stop
    } -ArgumentList $Url

    if ($ExpectedHash -ne "") {
        $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
        $actualHash = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
        $stream.Dispose()
        if ($actualHash -ne $ExpectedHash) {
            Write-Log -Message "Hash mismatch for $ToolName! Expected: $ExpectedHash, Got: $actualHash" -Level ERROR
            throw "Hash verification failed for $ToolName. The script may have been tampered with or updated."
        }
        Write-Log -Message "Hash verified for $ToolName" -Level SUCCESS
    }

    & ([ScriptBlock]::Create($scriptContent)) | Out-Host
}

function Invoke-SecureDownload {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$ToolName = "file",
        [string]$ExpectedHash = "",
        [int]$TimeoutSec = 60
    )

    Invoke-WithSpinner -Message "Downloading $ToolName" -ScriptBlock {
        param($u, $o, $t)
        Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -TimeoutSec $t -ErrorAction Stop
    } -ArgumentList $Url, $OutFile, $TimeoutSec

    if (-not (Test-Path $OutFile)) {
        throw "Download failed: $OutFile not found after download"
    }

    if ($ExpectedHash -ne "") {
        $actualHash = (Get-FileHash -Path $OutFile -Algorithm SHA256).Hash
        if ($actualHash -ne $ExpectedHash) {
            Write-Log -Message "Hash mismatch for $ToolName! Expected: $ExpectedHash, Got: $actualHash" -Level WARNING
            Write-Log -Message "The downloaded file may have been tampered with or updated." -Level WARNING
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
            throw "Hash verification failed for $ToolName"
        }
        Write-Log -Message "Hash verified for $ToolName" -Level SUCCESS
    }
}

function Confirm-ExternalTool {
    param(
        [Parameter(Mandatory)][psobject]$Tool
    )

    while ($true) {
        $items = @(
            "This tool will fetch and run a script from the web.",
            "Tool:   $($Tool.name)",
            "URL:    $($Tool.url)"
        )
        if ($Tool.docs) { $items += "Source: $($Tool.docs)" }
        $items += "---"
        $items += "Y › Run"
        $items += "N › Cancel"
        if ($Tool.docs) { $items += "R › Open source in browser" }

        $response = Show-InteractiveMenu -Title "External script execution" -Items $items -HideKeys
        switch ($response) {
            "Y" { return $true }
            "R" {
                if ($Tool.docs) {
                    Start-Process $Tool.docs
                    Write-Host "$Green  Opened project source in browser.$Reset"
                    Start-Sleep -Milliseconds 500
                }
            }
            default { return $false }
        }
    }
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$ToolId,
        [string]$SuccessMessage,
        [string]$ErrorMessage,
        [scriptblock]$OnSuccess,
        [scriptblock]$PreRun,
        [switch]$Wait,
        [switch]$SkipConfirm
    )

    $tool = Get-ToolConfig $ToolId
    if (-not $tool) {
        Write-Log -Message "Tool '$ToolId' not found in tools.json" -Level ERROR
        return $false
    }

    $effectiveType = $tool.type
    if ($tool.interactive -eq $true -and $effectiveType -eq "irm") { $effectiveType = "irm-interactive" }

    if ($effectiveType -in @("irm", "irm-interactive", "download") -and -not $SkipConfirm) {
        $confirmed = Confirm-ExternalTool -Tool $tool
        if (-not $confirmed) {
            Write-Log -Message "User cancelled $($tool.name) launch." -Level INFO
            return $false
        }
    }

    if ($PreRun) { & $PreRun }

    try {
        if ($tool.sha256) { $hash = $tool.sha256 } else { $hash = "" }
        switch ($effectiveType) {
            "irm" {
                Invoke-SecureScript -Url $tool.url -ToolName $tool.name -ExpectedHash $hash
            }
            "irm-interactive" {
                $tempScript = Join-Path $env:TEMP "$($tool.id)_$([guid]::NewGuid().ToString('N').Substring(0,8)).ps1"
                try {
                    Write-Log -Message "Downloading $($tool.name)..." -Level INFO
                    Invoke-WebRequest -Uri $tool.url -OutFile $tempScript -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
                    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" -Wait
                } finally {
                    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
                }
            }
            "download" {
                $downloadPath = Join-Path $env:TEMP $tool.filename
                Invoke-SecureDownload -Url $tool.url -OutFile $downloadPath -ToolName $tool.name -ExpectedHash $hash
                if ($OnSuccess) {
                    & $OnSuccess $downloadPath | Out-Host
                } else {
                    $startArgs = @{ FilePath = $downloadPath }
                    if ($Wait) { $startArgs.Wait = $true }
                    Start-Process @startArgs
                }
            }
            "browser" {
                Start-Process $tool.url
            }
            default {
                Write-Log -Message "Unknown tool type: $($tool.type)" -Level ERROR
                return $false
            }
        }

        if ($tool.type -ne "browser") {
            if ($SuccessMessage) { $msg = $SuccessMessage } else { $msg = "$($tool.name) completed successfully." }
            Write-Log -Message $msg -Level SUCCESS
        }
        if ($OnSuccess -and $tool.type -ne "download") {
            & $OnSuccess | Out-Host
        }
        return $true
    } catch {
        if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Failed to run $($tool.name)" }
        Write-Log -Message "${msg}: $($_.Exception.Message)" -Level ERROR

        # Browser fallback when network/download fails (timeout, DNS, blocked
        # domain, hash mismatch, etc.). Prefers $tool.fallbackUrl if defined,
        # otherwise opens $tool.docs (the project's homepage) so the user can
        # at least find the tool manually.
        $fallbackUrl = $null
        if ($tool.fallbackUrl) {
            $fallbackUrl = $tool.fallbackUrl
        } elseif ($tool.docs) {
            $fallbackUrl = $tool.docs
        }
        if ($fallbackUrl) {
            Write-Log -Message "Opening $fallbackUrl in browser as fallback..." -Level INFO
            try { Start-Process $fallbackUrl } catch {}
        }
        return $false
    }
}

function Assert-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log -Message "winget is not installed. Attempting to install..." -Level WARNING
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-Log -Message "winget installed successfully." -Level SUCCESS
                return $true
            }
        } catch {
            Write-Log -Message "Auto-install failed: $($_.Exception.Message)" -Level WARNING
        }
        Write-Log -Message "Opening Microsoft Store to install App Installer manually..." -Level INFO
        Start-Process "ms-windows-store://pdp?productid=9NBLGGH4NNS1"
        return $false
    }
    return $true
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name,
        [string]$Source = "",
        [switch]$ShowProgress
    )

    if (-not (Assert-WingetAvailable)) { return $false }

    try {
        $wingetArgs = @($PackageId, "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity")
        if (-not $ShowProgress) { $wingetArgs += "--silent" }
        if ($Source -ne "") { $wingetArgs += @("--source", $Source) }

        if ($ShowProgress) {
            Write-Host "$Cyan  Installing $Name...$Reset"
            & winget install @wingetArgs | Out-Host
        } else {
            # Silent install with animated spinner — winget runs in background
            # runspace, spinner animates in foreground.
            $exitCode = Invoke-WithSpinner -Message "Installing $Name" -ScriptBlock {
                param($wArgs)
                & winget install @wArgs 2>&1 | Out-Null
                $LASTEXITCODE
            } -ArgumentList (,@($wingetArgs))
            # Runspace returns as a collection; extract the int
            $LASTEXITCODE = if ($exitCode) { [int]@($exitCode)[-1] } else { 0 }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Log -Message "$Name installed." -Level SUCCESS
            return $true
        } elseif ($LASTEXITCODE -eq $WINGET_ALREADY_INSTALLED) {
            Write-Log -Message "$Name already installed." -Level SKIP
            return $true
        } else {
            Write-Log -Message "Failed to install $Name (exit code: $LASTEXITCODE)" -Level ERROR
            return $false
        }
    } catch {
        Write-Log -Message "Error installing ${Name}: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Invoke-NativeCommand {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$SuccessMessage = "",
        [string]$ErrorMessage = ""
    )

    $label = if ($SuccessMessage) { $SuccessMessage -replace '^\w+\s+', '' } else { "$Command $($Arguments[0])" }
    try {
        $code = Invoke-WithSpinner -Message $label -ScriptBlock {
            param($cmd, $cmdArgs)
            & $cmd @cmdArgs 2>&1 | Out-Null
            $LASTEXITCODE
        } -ArgumentList $Command, (,@($Arguments))

        $exitCode = if ($code) { [int]@($code)[-1] } else { 0 }
        if ($exitCode -ne 0) {
            if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Command failed: $Command $($Arguments -join ' ')" }
            Write-Log -Message "$msg (exit code: $exitCode)" -Level ERROR
            return $false
        }
        if ($SuccessMessage) {
            Write-Log -Message $SuccessMessage -Level SUCCESS
        }
        return $true
    } catch {
        if ($ErrorMessage) { $msg = $ErrorMessage } else { $msg = "Command failed: $Command" }
        Write-Log -Message "$msg - $($_.Exception.Message)" -Level ERROR
        return $false
    }
}
