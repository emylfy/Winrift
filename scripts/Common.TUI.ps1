function _Enter-RawUI {
    # Saves cursor visibility and CtrlC mode, hides cursor.
    # Returns a state hashtable to pass to _Exit-RawUI.
    $visible = try { [Console]::CursorVisible } catch { $true }
    $s = @{
        Visible = $visible
        CtrlC   = [Console]::TreatControlCAsInput
    }
    try { [Console]::CursorVisible = $false } catch { $null = $_ }
    return $s
}

function _Exit-RawUI {
    param([hashtable]$State)
    [Console]::TreatControlCAsInput = $State.CtrlC
    try { [Console]::CursorVisible = $State.Visible } catch { $null = $_ }
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
        [switch]$HideKeys,
        [hashtable]$Descriptions = $null,
        [int]$SplitAt = 0,
        [string]$TitleRight = $null
    )

    $hasVpTop = $PSBoundParameters.ContainsKey('VpTop')
    $hasSplit = ($null -ne $Descriptions -and $SplitAt -gt 0 -and -not $NoBox)
    $splitRightW = 0
    $inPinned = $false

    $ESC = [char]0x1b
    $h  = [string][char]0x2500
    $v  = [string][char]0x2502
    $tl = [string][char]0x256D
    $tr = [string][char]0x256E
    $bl = [string][char]0x2570
    $br = [string][char]0x256F
    $EOL = "$ESC[K"

    # Width calculation
    $titlePlain = $Title -replace '\x1b\[[0-9;]*m', ''
    $maxLen = $titlePlain.Length + 2
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
    } elseif ($hasSplit) {
        $itemInnerW = $SplitAt - 5
    } else {
        $itemInnerW = $w - 5
    }
    if ($null -ne $Checked) { $itemInnerW -= 4 }

    $BP = "$Bold$Dim"
    if ($hasSplit) {
        $splitMinW = $SplitAt + 3 + 38
        if ($w -lt $splitMinW) { $w = $splitMinW }
        $splitRightW = $w - $SplitAt - 3
    }
    $rightPlain = if ($TitleRight) { $TitleRight -replace '\x1b\[[0-9;]*m', '' } else { $null }
    $topFill = $w - ("$h $titlePlain ").Length
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
        if ($Items[$idx] -match '^---\s+(.+?)\s*-*$') {
            if ($Matches[1].TrimEnd('- ').Length -gt 0) { return 2 } else { return 1 }
        }
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
                if ($idx -ne $currentVp) { $out.Add("") }
                if ($sec.Length -gt 0) { $out.Add("  $Cyan$sec$Reset") }
            } elseif ($hasSplit -and -not $inPinned) {
                $out.Add("$BP $v$Reset$(' ' * $SplitAt)")
                if ($sec.Length -gt 0) {
                    $sp = [math]::Max(0, $SplitAt - 2 - $sec.Length)
                    $out.Add("$BP $v$Reset  $Cyan$sec$Reset$(' ' * $sp)")
                }
            } else {
                $out.Add("$BP $v$Reset$(" " * $w)$BP$v$Reset")
                if ($sec.Length -gt 0) {
                    $pad = $w - ("  $sec").Length; if ($pad -lt 0) { $pad = 0 }
                    $out.Add("$BP $v$Reset  $Cyan$sec$Reset$(" " * $pad)$BP$v$Reset")
                }
            }
            return $out
        }
        if ($item -eq "---") {
            if ($NoBox) {
                $out.Add("")
            } elseif ($hasSplit -and -not $inPinned) {
                $out.Add("$BP $v$Reset$(' ' * $SplitAt)")
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
        # In split mode: strip " - description" from left column (shown in right panel)
        if ($hasSplit -and -not $inPinned -and $displayItem -match '^(.+?)\s+-\s+.+$') {
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
        } elseif ($hasSplit -and -not $inPinned) {
            # Surrogate pairs (Nerd Font supplemental chars U+F0000+) = 2 .NET chars but 1 display column.
            # $plain.Length overcounts by 1 per pair → add surrogateCount back to splitPad.
            $surrogateCount = 0
            for ($ci = 0; $ci -lt $plain.Length - 1; $ci++) {
                if ([char]::IsHighSurrogate($plain[$ci]) -and [char]::IsLowSurrogate($plain[$ci + 1])) {
                    $surrogateCount++; $ci++
                }
            }
            $splitPad = [math]::Max(0, $SplitAt - 3 - $plain.Length + $surrogateCount)
            $out.Add("$BP $v$Reset $ptr$chk$rendered$(' ' * $splitPad)")
        } else {
            $out.Add("$BP $v$Reset $ptr$chk$rendered$(" " * $pad)$BP$v$Reset")
        }

        # Warning line for label~warning items (always 2 rows to keep layout stable)
        if ($warnText -ne "") {
            if ($isCur) {
                $warnLine = "      $Yellow$([char]0x21) $warnText$Reset"
                $warnPlain = "      ! $warnText"
                if ($NoBox) {
                    $out.Add($warnLine)
                } elseif ($hasSplit -and -not $inPinned) {
                    $wp = [math]::Max(0, $SplitAt - 1 - $warnPlain.Length)
                    $out.Add("$BP $v$Reset $warnLine$(' ' * $wp)")
                } else {
                    $warnPad = [math]::Max(0, $w - 1 - $warnPlain.Length)
                    $out.Add("$BP $v$Reset $warnLine$(" " * $warnPad)$BP$v$Reset")
                }
            } else {
                if ($NoBox) { $out.Add("") }
                elseif ($hasSplit -and -not $inPinned) { $out.Add("$BP $v$Reset$(' ' * $SplitAt)") }
                else { $out.Add("$BP $v$Reset$(" " * $w)$BP$v$Reset") }
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
        if ($rightPlain -and $topFill -gt $rightPlain.Length + 4) {
            $midFill = $topFill - $rightPlain.Length - 3
            $lines.Add("$BP $tl$h $Bold$Ice$Title$BP $($h * $midFill) $Dim$TitleRight$Reset $BP$h$tr$Reset")
        } else {
            $lines.Add("$BP $tl$h $Bold$Ice$Title$BP $($h * $topFill)$tr$Reset")
        }
        $lines.Add((& $buildEmptyRow))
    }

    # Pre-compute right column description lines for split mode
    $descLines = @()
    $_splitDescIdx = 0
    if ($hasSplit -and $Descriptions -and $Descriptions.ContainsKey($HighlightIndex)) {
        $descW = $splitRightW - 2
        $tempDesc = [System.Collections.Generic.List[string]]::new()
        foreach ($dl in @($Descriptions[$HighlightIndex])) {
            $dlPlain = $dl -replace '\x1b\[[0-9;]*m', ''
            if ($dlPlain.Length -le $descW) {
                $tempDesc.Add($dl)
            } else {
                $cur = ''
                foreach ($word in ($dlPlain -split ' ')) {
                    $cand = if ($cur) { "$cur $word" } else { $word }
                    if ($cand.Length -le $descW) { $cur = $cand }
                    else { if ($cur) { $tempDesc.Add($cur) }; $cur = $word }
                }
                if ($cur) { $tempDesc.Add($cur) }
            }
        }
        $descLines = $tempDesc.ToArray()
    }

    # Scroll-up indicator
    if ($needsScroll) {
        if ($hasSplit) {
            $upLeft = if ($currentVp -gt 0) {
                $lbl = "$([char]0x25B2) $([char]0xB7)$([char]0xB7)$([char]0xB7)"
                $lp = [math]::Max(0,[math]::Floor(($SplitAt-5)/2))
                "$BP $v$Reset$(' '*$lp)$Dim$lbl$Reset$(' '*([math]::Max(0,$SplitAt-5-$lp)))"
            } else { "$BP $v$Reset$(' '*$SplitAt)" }
            $_src = if ($_splitDescIdx -lt $descLines.Count) { $descLines[$_splitDescIdx] } else { "" }
            $_srp = [math]::Max(0, $splitRightW - ($_src -replace '\x1b\[[0-9;]*m','').Length)
            $lines.Add("$upLeft $Dim$v$Reset $_src$(' '*$_srp)$BP$v$Reset")
            $_splitDescIdx++
        } elseif ($currentVp -gt 0) {
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
                if ($hasSplit) {
                    $_src = if ($_splitDescIdx -lt $descLines.Count) { $descLines[$_splitDescIdx] } else { "" }
                    $_srp = [math]::Max(0, $splitRightW - ($_src -replace '\x1b\[[0-9;]*m','').Length)
                    $lines.Add("$line $Dim$v$Reset $_src$(' '*$_srp)$BP$v$Reset")
                    $_splitDescIdx++
                } else { $lines.Add($line) }
                $rendered++
            }
        }
        $i++
    }
    $lastRenderedScrollable = $i  # exclusive end of what we drew

    # Fill remaining viewport rows with empty lines to keep box height stable
    while ($rendered -lt $visibleRows) {
        if ($hasSplit) {
            $_src = if ($_splitDescIdx -lt $descLines.Count) { $descLines[$_splitDescIdx] } else { "" }
            $_srp = [math]::Max(0, $splitRightW - ($_src -replace '\x1b\[[0-9;]*m','').Length)
            $lines.Add("$BP $v$Reset$(' '*$SplitAt) $Dim$v$Reset $_src$(' '*$_srp)$BP$v$Reset")
            $_splitDescIdx++
        } else { $lines.Add((& $buildEmptyRow)) }
        $rendered++
    }

    # Scroll-down indicator
    if ($needsScroll) {
        if ($hasSplit) {
            $dnLeft = if ($lastRenderedScrollable -lt $scrollableEnd) {
                $lbl = "$([char]0x25BC) $([char]0xB7)$([char]0xB7)$([char]0xB7)"
                $lp = [math]::Max(0,[math]::Floor(($SplitAt-5)/2))
                "$BP $v$Reset$(' '*$lp)$Dim$lbl$Reset$(' '*([math]::Max(0,$SplitAt-5-$lp)))"
            } else { "$BP $v$Reset$(' '*$SplitAt)" }
            $_src = if ($_splitDescIdx -lt $descLines.Count) { $descLines[$_splitDescIdx] } else { "" }
            $_srp = [math]::Max(0, $splitRightW - ($_src -replace '\x1b\[[0-9;]*m','').Length)
            $lines.Add("$dnLeft $Dim$v$Reset $_src$(' '*$_srp)$BP$v$Reset")
            $_splitDescIdx++
        } elseif ($lastRenderedScrollable -lt $scrollableEnd) {
            $lines.Add((& $buildScrollIndicator 'down'))
        } else {
            $lines.Add((& $buildEmptyRow))
        }
    }

    # Pinned footer (always full width, no split)
    $inPinned = $true
    for ($i = $pinnedStart; $i -lt $Items.Count; $i++) {
        $itemLines = & $buildItemLines $i
        foreach ($line in $itemLines) { $lines.Add($line) }
    }
    $inPinned = $false

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
    # Persistent menu loop — executes action callbacks and stays open until exit.
    # Intentional differences from Show-InteractiveMenu and Show-MultiSelect:
    #   - Up/Down do NOT wrap around (top/bottom clamp). Wrapping would make it easy
    #     to accidentally trigger the exit action when cycling past the last item.
    #   - Actions run arbitrary code; loop continues after each action returns.
    #   - Supports breadcrumb tracking and live title redraws via TitleSuffix.
    param(
        [string]$Title,
        [string[]]$Items,
        [hashtable]$Actions,
        [string]$Prompt = " ",
        [string]$ExitKey = $null,
        [scriptblock]$OnExit = $null,
        [hashtable]$Descriptions = $null,
        [int]$SplitAt = 0,
        [scriptblock]$TitleSuffix = $null,
        [switch]$HideKeys
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
    $_ui = _Enter-RawUI
    Clear-Host
    $prevLines = 0
    $vpTop = 0

    try {
        while ($true) {
            $drawRight = if ($TitleSuffix) { & $TitleSuffix } else { $null }
            $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -Descriptions $Descriptions -SplitAt $SplitAt -TitleRight $drawRight -HideKeys:$HideKeys

            # Wait for keypress. When TitleSuffix is set, poll periodically to
            # redraw live stats. Otherwise just block on ReadKey (no CPU waste).
            [Console]::TreatControlCAsInput = $true
            if ($TitleSuffix) {
                while (-not $Host.UI.RawUI.KeyAvailable) {
                    Start-Sleep -Milliseconds 500
                    $drawRight = & $TitleSuffix
                    $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -Descriptions $Descriptions -SplitAt $SplitAt -TitleRight $drawRight -HideKeys:$HideKeys
                }
            }
            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            [Console]::TreatControlCAsInput = $_ui.CtrlC
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
                $selectedLabel = ($Items[$selectIdx[$cursor]] -replace '\x1b\[[0-9;]*m', '' -replace '^\s*\S+\s*[›>]\s*', '').Trim()
                Write-Log -Message "[$cleanTitle] › $selectedLabel" -Level INFO
                try { [Console]::CursorVisible = $true } catch { $null = $_ }
                & $Actions[$actionKey]
                try { [Console]::CursorVisible = $false } catch { $null = $_ }
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
        _Exit-RawUI $_ui
    }
}

function Show-InteractiveMenu {
    # Single-shot arrow-navigable menu — returns the selected key or $null on Escape.
    # Intentional differences from Invoke-MenuLoop and Show-MultiSelect:
    #   - Up/Down WRAP AROUND (top→bottom, bottom→top). Safe here because no action
    #     fires on navigation — the user explicitly presses Enter to confirm.
    #   - Returns immediately on Enter/character press; does not loop.
    #   - No action hashtable; no breadcrumb tracking.
    # -NoClear: skip the initial Clear-Host so callers can print prose above the menu.
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
    $_ui = _Enter-RawUI
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
            [Console]::TreatControlCAsInput = $_ui.CtrlC
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
        _Exit-RawUI $_ui
    }
}

function Show-MultiSelect {
    # Multi-select checklist — returns an array of selected keys on Enter, empty array on Escape.
    # Intentional differences from Invoke-MenuLoop and Show-InteractiveMenu:
    #   - Up/Down do NOT wrap (clamp at ends, same as Invoke-MenuLoop).
    #   - Space toggles the highlighted item; Enter confirms the whole selection.
    #   - 'A' toggles all items at once — unique to this loop.
    #   - Returns key strings extracted from items (token before ›), not item indices.
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
    $_ui = _Enter-RawUI
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
            [Console]::TreatControlCAsInput = $_ui.CtrlC
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
        _Exit-RawUI $_ui
    }
}

function Show-InfoBox {
    # Lightweight non-interactive display — title + items, no cursor, no input.
    # Replaces raw Write-Host blocks for tables/reports that don't need navigation.
    param(
        [string]$Title,
        [string[]]$Items
    )
    Write-Host ""
    Write-Host "  $Bold$Ice $Title $Reset"
    Write-Host ""
    foreach ($item in $Items) {
        if ($item -match '^---\s+(.+?)\s*-*$') {
            Write-Host ""
            Write-Host "  $Cyan$($Matches[1].TrimEnd('- '))$Reset"
        } elseif ($item -eq "---") {
            Write-Host ""
        } else {
            Write-Host "  $item"
        }
    }
    Write-Host ""
}