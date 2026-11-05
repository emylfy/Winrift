function _Enter-RawUI {
    if ($IsWindows -and -not ('Winrift.ConsoleInput' -as [type])) {
        try {
            Add-Type -ErrorAction Stop -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Winrift {
    public static class ConsoleInput {
        [StructLayout(LayoutKind.Explicit, Size = 20)]
        private struct InputRecord {
            [FieldOffset(0)] public ushort Type;
            [FieldOffset(4)] public int KeyDown;
        }

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetStdHandle(int kind);
        [DllImport("kernel32.dll")]
        private static extern bool GetConsoleMode(IntPtr handle, out uint mode);
        [DllImport("kernel32.dll")]
        private static extern bool SetConsoleMode(IntPtr handle, uint mode);
        [DllImport("kernel32.dll", EntryPoint = "PeekConsoleInputW")]
        private static extern bool PeekConsoleInput(IntPtr handle, out InputRecord record, uint count, out uint read);
        [DllImport("kernel32.dll", EntryPoint = "ReadConsoleInputW")]
        private static extern bool ReadConsoleInput(IntPtr handle, out InputRecord record, uint count, out uint read);

        public static uint? EnableResizeEvents() {
            var handle = GetStdHandle(-10);
            if (GetConsoleMode(handle, out uint mode) && SetConsoleMode(handle, mode | 0x0008))
                return mode;
            return null;
        }

        public static void RestoreMode(uint mode) {
            SetConsoleMode(GetStdHandle(-10), mode);
        }

        public static bool ReadResizeEvent() {
            var handle = GetStdHandle(-10);
            // Leave keyboard records to Console.ReadKey, which handles repeats.
            while (PeekConsoleInput(handle, out InputRecord record, 1, out uint count) &&
                   count != 0 && (record.Type != 0x0001 || record.KeyDown == 0)) {
                if (!ReadConsoleInput(handle, out record, 1, out count) || count == 0)
                    break;
                if (record.Type == 0x0004)
                    return true;
            }
            return false;
        }
    }
}
'@
        } catch {
            # Keep size polling available if native console input is unavailable.
        }
    }
    # Saves cursor visibility and CtrlC mode, hides cursor.
    # Returns a state hashtable to pass to _Exit-RawUI.
    $visible = try { [Console]::CursorVisible } catch { $true }
    $s = @{
        Visible = $visible
        CtrlC   = [Console]::TreatControlCAsInput
        InputMode = if ('Winrift.ConsoleInput' -as [type]) { [Winrift.ConsoleInput]::EnableResizeEvents() }
    }
    try { [Console]::CursorVisible = $false } catch { $null = $_ }
    return $s
}

function _Exit-RawUI {
    param([hashtable]$State)
    if ($null -ne $State.InputMode) { [Winrift.ConsoleInput]::RestoreMode($State.InputMode) }
    [Console]::TreatControlCAsInput = $State.CtrlC
    try { [Console]::CursorVisible = $State.Visible } catch { $null = $_ }
}

function ConvertTo-WinriftLine {
    param([string]$Text, [int]$Width)
    $plain = ($Text -replace '\x1b\][^\x07]*(?:\x07|\x1b\\)', '') -replace '\x1b\[[0-9;?]*[A-Za-z]', ''
    $plain = ($plain.Replace("`t",'  ')) -replace '[\x00-\x1f\x7f]', ''
    if($Width -le 0){return ''}
    # Most menu text and its markers occupy one cell per character.
    if ($plain -cmatch '^[ -~…○●✓–↑↓←→↵›↗·]*$') {
        if ($plain.Length -le $Width) { return $plain }
        return $plain.Substring(0, $Width - 1) + '…'
    }
    $elements=[Collections.Generic.List[object]]::new();$total=0
    $enumerator=[Globalization.StringInfo]::GetTextElementEnumerator($plain)
    while($enumerator.MoveNext()){
        $element=[string]$enumerator.Current;$code=[char]::ConvertToUtf32($element,0)
        $wide=($code -ge 0x1100 -and $code -le 0x115f) -or ($code -ge 0x2e80 -and $code -le 0xa4cf) -or ($code -ge 0xac00 -and $code -le 0xd7a3) -or ($code -ge 0xf900 -and $code -le 0xfaff) -or ($code -ge 0xfe10 -and $code -le 0xfe6f) -or ($code -ge 0xff00 -and $code -le 0xff60) -or ($code -ge 0xffe0 -and $code -le 0xffe6) -or ($code -ge 0x1f000 -and $code -le 0x1faff) -or ($code -ge 0x20000 -and $code -le 0x3fffd)
        $cells=if($wide){2}else{1}
        $elements.Add(@{Text=$element;Width=$cells});$total+=$cells
    }
    if($total -le $Width){return $plain}
    if($Width -eq 1){return '…'}
    $builder=[Text.StringBuilder]::new();$used=0
    foreach($element in $elements){if($used+$element.Width -gt $Width-1){break};[void]$builder.Append($element.Text);$used+=$element.Width}
    return $builder.ToString()+'…'
}
function Get-WinriftMenuFrame {
    # Pure layout: terminal dimensions are supplied by the console adapter.
    param(
        [string]$Title, [string[]]$Items, [int]$HighlightIndex = -1,
        [bool[]]$Checked, [string[]]$Markers, [hashtable]$Descriptions, [string]$Hint,
        [int]$Width = 80, [int]$Height = 25, [int]$Top = 0, [switch]$HideHint, [hashtable]$FocusedDescriptions
    )
    $widthBudget = [math]::Max(1, $Width - 5)
    $rows = [System.Collections.Generic.List[string]]::new()
    $rows.Add('')
    $rows.Add("    ${Bold}${Ice}$(ConvertTo-WinriftLine $Title ([math]::Max(1,$widthBudget - 1)))$Reset")
    $rows.Add('')
    # Reserve title, context, hint and a final console row to avoid wrapping.
    $focusedDescription = if ($FocusedDescriptions) { $FocusedDescriptions[$HighlightIndex] }
    $descriptionRows = if ($focusedDescription) { 1 } else { 0 }
    $visible = [math]::Max(1, $Height - 9 - $descriptionRows)
    if ($Items.Count -le $Height - 7 - $descriptionRows -and -not $Descriptions -and -not ($Items -like "*~*")) {
        $visible = $Items.Count
    }
    $topLimit = [math]::Max(0, $Items.Count - $visible)
    $Top = [math]::Clamp($Top, 0, $topLimit)
    if ($HighlightIndex -ge 0) {
        if ($HighlightIndex -lt $Top) { $Top = $HighlightIndex }
        if ($HighlightIndex -ge $Top + $visible) { $Top = $HighlightIndex - $visible + 1 }
    }
    # Labels and their muted trailing glyphs share a column, as in Macrift.
    $labelWidth = 1
    foreach ($entry in $Items) {
        if ($entry -like '---*') { continue }
        $plainLabel = (($entry -replace '^\s*[^\s]+\s*[›>]\s*', '') -split '~',2)[0]
        $plainLabel = ($plainLabel -replace '\s+[›↗]\s*$','').TrimEnd()
        $labelWidth = [math]::Max($labelWidth, $plainLabel.Length)
    }
    if ($null -ne $Checked) { $labelWidth += 2 }
    $labelWidth = [math]::Min($labelWidth, [math]::Max(1,$widthBudget - 3))
    $last = [math]::Min($Items.Count, $Top + $visible)
    if ($Top -gt 0) { $rows[2] = "     ${Dim}▲ …$Reset" }
    for ($i = $Top; $i -lt $last; $i++) {
        $item = $Items[$i]
        if ($item -eq '---' -or $item -match '^---\s+-+\s*$') { $rows.Add(''); continue }
        if ($item -match '^---\s+(.+?)\s*-*$') {
            $rows.Add("    $Dim$(ConvertTo-WinriftLine $Matches[1].TrimEnd('- ') ($widthBudget - 2))$Reset")
            continue
        }
        $label = $item -replace '^\s*[^\s]+\s*[›>]\s*', ''
        $label = ($label -split '~', 2)[0]
        $glyph = ''
        if ($label -match '\s+([›↗])\s*$') { $glyph = $Matches[1]; $label = $label -replace '\s+[›↗]\s*$', '' }
        $label = $label.TrimEnd()
        $marker = ''
        if ($null -ne $Checked -and $i -lt $Checked.Count) {
            $marker = if ($Checked[$i]) { '● ' } elseif ($Markers -and $Markers[$i]) { $Markers[$i] + ' ' } else { '○ ' }
        }
        $label = ConvertTo-WinriftLine ($marker + $label) $labelWidth
        $tail = if ($glyph) { ' ' * [math]::Max(1,$labelWidth - $label.Length + 1) + "$Dim$glyph$Reset" } else { '' }
        if ($i -eq $HighlightIndex) {
            $rows.Add("   ${Bold}${Cyan}▌${Reset} ${Bold}$label${Reset}$tail")
            if ($focusedDescription) {
                $rows.Add("       $Dim$(ConvertTo-WinriftLine $focusedDescription ($Width - 8))$Reset")
            }
        } else { $rows.Add("     $label$tail") }
    }
    $rows.Add($(if ($last -lt $Items.Count) { "     ${Dim}▼ …$Reset" } else { '' }))
    $context = ''
    if ($Descriptions -and $Descriptions.ContainsKey($HighlightIndex)) {
        $context = @($Descriptions[$HighlightIndex]) -join ' '
    } elseif ($HighlightIndex -ge 0 -and $Items[$HighlightIndex] -like '*~*') {
        $context = ($Items[$HighlightIndex] -split '~', 2)[1]
    }
    if ($context) {
        $rows.Add("     $Dim$(ConvertTo-WinriftLine $context ([math]::Max(1,$widthBudget - 2)))$Reset")
        $rows.Add('')
    }
    if (-not $HideHint) {
        if (-not $Hint) {
            $Hint = if ($null -ne $Checked) { 'Space select · A select applicable · ? details · Enter review · Esc back' } else { '↑↓ move · →/↵ select · ←/Esc back' }
        }
        $rows.Add("  $Dim$(ConvertTo-WinriftLine $Hint ([math]::Max(1,$Width - 3)))$Reset")
    }
    # Very short windows still show the active row; no negative dimensions.
    if ($Height -lt 9) {
        $rows.Clear()
        if ($HighlightIndex -ge 0) {
            $label = $Items[$HighlightIndex] -replace '^\s*[^\s]+\s*[›>]\s*', ''
            $rows.Add("${Cyan}▌${Reset} $(ConvertTo-WinriftLine $label ([math]::Max(1, $Width - 3)))")
        }
    }
    return @{ Lines = $rows.ToArray(); Top = $Top }
}

function _Draw-InteractiveBox {
    # Compatibility adapter for existing callers; all routes render frameless.
    param(
        [string]$Title, [string[]]$Items, [int]$HighlightIndex = -1,
        [bool[]]$Checked = $null, [string[]]$Markers, [int]$PrevLines = 0, [ref]$VpTop,
        [switch]$NoBox, [string]$Hint, [switch]$HideKeys,
        [hashtable]$Descriptions, [int]$SplitAt = 0, [string]$TitleRight, [switch]$HideHint, [hashtable]$FocusedDescriptions
    )
    $width = try { [Console]::WindowWidth } catch { 80 }
    $height = try { [Console]::WindowHeight } catch { 25 }
    $resized = $PrevLines -gt 0 -and ($width -ne $script:WinriftFrameWidth -or $height -ne $script:WinriftFrameHeight)
    $script:WinriftFrameWidth = $width
    $script:WinriftFrameHeight = $height
    $width = [math]::Max(4, $width)
    $height = [math]::Max(2, $height)
    $top = if ($null -ne $VpTop) { $VpTop.Value } else { 0 }
    $frame = Get-WinriftMenuFrame -Title $Title -Items $Items -HighlightIndex $HighlightIndex -Checked $Checked -Markers $Markers -Descriptions $Descriptions -Hint $Hint -Width $width -Height $height -Top $top -HideHint:$HideHint -FocusedDescriptions $FocusedDescriptions
    if ($null -ne $VpTop) { $VpTop.Value = $frame.Top }
    $esc = [char]27
    $sb = [Text.StringBuilder]::new()
    [void]$sb.Append("$esc[?2026h")
    if ($resized) {
        # Clear reflowed rows from scrollback after clearing the viewport.
        [void]$sb.Append("$esc[2J$esc[3J$esc[H")
    } elseif ($PrevLines -ge $height) { [void]$sb.Append("$esc[H$esc[J") }
    elseif ($PrevLines -gt 0) { [void]$sb.Append("$esc[${PrevLines}A`r") }
    foreach ($line in $frame.Lines) { [void]$sb.Append("$line$esc[K`n") }
    [void]$sb.Append("$esc[J$esc[?2026l")
    [Console]::Write($sb.ToString())
    return $frame.Lines.Count
}
function Read-WinriftMenuKey {
    $nativeInput = 'Winrift.ConsoleInput' -as [type]
    while ($true) {
        if ($nativeInput -and [Winrift.ConsoleInput]::ReadResizeEvent()) {
            $script:WinriftFrameWidth = -1
            return [pscustomobject]@{ VirtualKeyCode = 0; Character = [char]0 }
        }
        if ([Console]::WindowWidth -ne $script:WinriftFrameWidth -or [Console]::WindowHeight -ne $script:WinriftFrameHeight) {
            return [pscustomobject]@{ VirtualKeyCode = 0; Character = [char]0 }
        }
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            return [pscustomobject]@{ VirtualKeyCode = [int]$key.Key; Character = $key.KeyChar }
        }
        Start-Sleep -Milliseconds 25
    }
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
        [switch]$HideKeys,
        [scriptblock]$OnTab, [scriptblock]$HintProvider,
        [string]$NextKey,
        [switch]$HideHint
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
            $drawHint = if ($HintProvider) { & $HintProvider } else { $null }
            $drawRight = $TitleSuffix ? (& $TitleSuffix) : $null
            $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -Descriptions $Descriptions -SplitAt $SplitAt -TitleRight $drawRight -HideKeys:$HideKeys -Hint $drawHint -HideHint:$HideHint

            # Wait for keypress. When TitleSuffix is set, poll periodically to
            # redraw live stats. Otherwise just block on ReadKey (no CPU waste).
            [Console]::TreatControlCAsInput = $true
            if ($TitleSuffix) {
                while (-not [Console]::KeyAvailable) {
                    Start-Sleep -Milliseconds 500
                    if ([Console]::WindowWidth -ne $script:WinriftFrameWidth -or [Console]::WindowHeight -ne $script:WinriftFrameHeight) { break }
                    $drawRight = & $TitleSuffix
                    $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -Descriptions $Descriptions -SplitAt $SplitAt -TitleRight $drawRight -HideKeys:$HideKeys -Hint $drawHint -HideHint:$HideHint
                }
            }
            $k = Read-WinriftMenuKey
            [Console]::TreatControlCAsInput = $_ui.CtrlC
            $vk = $k.VirtualKeyCode

            # Ctrl+C → treat as "back" (same as Escape)
            if ($k.Character -eq [char]3) {
                if ($ExitKey) { if ($OnExit) { & $OnExit }; return }
                continue
            }

            if ($vk -eq 9 -and $OnTab) {
                & $OnTab
                Clear-Host; $prevLines=0; $vpTop=0
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

            if ($NextKey -and $selKey -eq $NextKey) { return 'Next' }

            # Execute action
            $actionKey = $null
            if ($Actions.ContainsKey($selKey)) { $actionKey = $selKey }
            elseif ($Actions.ContainsKey($selKey.ToUpper())) { $actionKey = $selKey.ToUpper() }
            if ($actionKey) {
                $selectedLabel = ($Items[$selectIdx[$cursor]] -replace '\x1b\[[0-9;]*m', '' -replace '^\s*\S+\s*[›>]\s*', '').Trim()
                Write-Log -Message "[$cleanTitle] › $selectedLabel" -Level INFO -Quiet
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
        [switch]$HideKeys,
        [switch]$ActionsOnly
    )

    $selectIdx = [System.Collections.Generic.List[int]]::new()
    $keyMap = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $t = $Items[$i]
        if ($t -ne "---" -and $t -notmatch '^---\s+' -and (-not $ActionsOnly -or $t -match '^\s*[^\s]+\s*[›>]')) {
            $selectIdx.Add($i)
            if ($t -match '^\s*([^\s]+)\s*[›>]') {
                $keyMap[$i] = $Matches[1]
            }
        }
    }
    if ($selectIdx.Count -eq 0) { return $null }

    # Auto-confirm: if NO_CONFIRM=1 and menu has "Y ›" item — return "Y" without rendering
    if ($env:WINRIFT_NO_CONFIRM -eq "1") {
        $yItem = $Items | Where-Object { $_ -match '^\s*Y\s*[›>]' } | Select-Object -First 1
        if ($yItem) { return "Y" }
    }

    $cursor = 0
    $_ui = _Enter-RawUI
    if (-not $NoClear) { Clear-Host }
    $prevLines = 0
    $vpTop = 0

    try {
        while ($true) {
            if ($HideKeys) {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop) -HideKeys
            } else {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -PrevLines $prevLines -VpTop ([ref]$vpTop)
            }

            [Console]::TreatControlCAsInput = $true
            $k = Read-WinriftMenuKey
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
                if ($keyMap.ContainsKey($selectIdx[$cursor])) { return $keyMap[$selectIdx[$cursor]] }
                continue
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
        [bool[]]$Disabled, [string[]]$Markers, [hashtable]$Descriptions,
        [switch]$NoBox,
        [switch]$DetailsOnly,
        [hashtable]$FocusedDescriptions,
        [scriptblock]$OnSelectionChanged
    )

    $selectIdx = [System.Collections.Generic.List[int]]::new()
    $inlineDescriptions = if (-not $DetailsOnly) { $Descriptions }
    $checked = [bool[]]::new($Items.Count)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        if ($Items[$i] -ne "---" -and $Items[$i] -notmatch '^---\s+') {
            $selectIdx.Add($i)
            if ($Defaults -and $i -lt $Defaults.Count -and -not ($Disabled -and $Disabled[$i])) { $checked[$i] = $Defaults[$i] }
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
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -Checked $checked -Markers $Markers -Descriptions $inlineDescriptions -FocusedDescriptions $FocusedDescriptions -PrevLines $prevLines -VpTop ([ref]$vpTop) -NoBox
            } else {
                $prevLines = _Draw-InteractiveBox -Title $Title -Items $Items -HighlightIndex $selectIdx[$cursor] -Checked $checked -Markers $Markers -Descriptions $inlineDescriptions -FocusedDescriptions $FocusedDescriptions -PrevLines $prevLines -VpTop ([ref]$vpTop)
            }

            [Console]::TreatControlCAsInput = $true
            $k = Read-WinriftMenuKey
            [Console]::TreatControlCAsInput = $_ui.CtrlC
            $vk = $k.VirtualKeyCode
            $ch = $k.Character

            # Ctrl+C → cancel
            if ($ch -eq [char]3) { return @() }

            if ($vk -eq 38 -and $cursor -gt 0) { $cursor--; continue }
            if ($vk -eq 40 -and $cursor -lt $selectIdx.Count - 1) { $cursor++; continue }

            if ($vk -eq 32) {  # Space — toggle
                if (-not ($Disabled -and $Disabled[$selectIdx[$cursor]])) { $checked[$selectIdx[$cursor]] = -not $checked[$selectIdx[$cursor]] }
                if ($OnSelectionChanged) {
                    $keys = @()
                    foreach ($index in $selectIdx) { if ($checked[$index] -and $Items[$index] -match '^\s*([^\s]+)\s*[›>]') { $keys += $Matches[1] } }
                    & $OnSelectionChanged $keys
                }
                continue
            }

            if ($ch -eq 'a' -or $ch -eq 'A') {  # Toggle all
                $allOn = ($selectIdx | ForEach-Object { $checked[$_] }) -notcontains $false
                foreach ($si in $selectIdx) { if (-not ($Disabled -and $Disabled[$si])) { $checked[$si] = $true } }
                if ($OnSelectionChanged) {
                    $keys = @()
                    foreach ($index in $selectIdx) { if ($checked[$index] -and $Items[$index] -match '^\s*([^\s]+)\s*[›>]') { $keys += $Matches[1] } }
                    & $OnSelectionChanged $keys
                }
                continue
            }

            if ($ch -eq '?' -and $Descriptions -and $Descriptions.ContainsKey($selectIdx[$cursor])) {
                Show-InfoBox -Title 'Current / Proposed / Details' -Items @($Descriptions[$selectIdx[$cursor]])
                Wait-ForUser
                Clear-Host; $prevLines = 0
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

            if ($vk -eq 27 -or $vk -eq 37) { return @() }  # Escape — cancel
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