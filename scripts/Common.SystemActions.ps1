function Invoke-WinriftSystemParameters {
    param([ValidateSet('StickyKeys','ToggleKeys','Keyboard Response','MenuDelay')][string]$Setting,[int]$Value,[switch]$Set)
    if(-not ('Winrift.SystemParameters' -as [type])){
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Winrift {
  public static class SystemParameters {
    [DllImport("user32.dll", EntryPoint="SystemParametersInfoW", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool Call(uint action, uint parameter, IntPtr data, uint flags);
  }
}
"@
    }
    $getAction=0;$setAction=0;$size=8
    switch($Setting){
        'StickyKeys'{$getAction=0x003A;$setAction=0x003B}
        'ToggleKeys'{$getAction=0x0034;$setAction=0x0035}
        'Keyboard Response'{$getAction=0x0032;$setAction=0x0033;$size=24}
        'MenuDelay'{$getAction=0x006A;$setAction=0x006B;$size=4}
    }
    $memory=[Runtime.InteropServices.Marshal]::AllocHGlobal($size)
    try{
        for($offset=0;$offset -lt $size;$offset+=4){[Runtime.InteropServices.Marshal]::WriteInt32($memory,$offset,0)}
        if($Setting -ne 'MenuDelay'){[Runtime.InteropServices.Marshal]::WriteInt32($memory,0,$size)}
        if(-not [Winrift.SystemParameters]::Call($getAction,$size,$memory,0)){throw [ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error())}
        if($Set){
            if($Setting -eq 'MenuDelay'){
                $success=[Winrift.SystemParameters]::Call($setAction,$Value,[IntPtr]::Zero,3)
            }else{
                # Preserve all timing fields returned by SPI_GETFILTERKEYS.
                [Runtime.InteropServices.Marshal]::WriteInt32($memory,4,$Value)
                $success=[Winrift.SystemParameters]::Call($setAction,$size,$memory,3)
            }
            if(-not $success){throw [ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error())}
            return
        }
        $offset=if($Setting -eq 'MenuDelay'){0}else{4}
        return [Runtime.InteropServices.Marshal]::ReadInt32($memory,$offset)
    }finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($memory)}
}
function Get-WinriftSystemValue {
    param([string]$Id)
    if($Id.StartsWith('Environment.')){return [Environment]::GetEnvironmentVariable($Id.Substring(12),'Machine')}
    if($Id.StartsWith('Feature.')){return [string](Get-WindowsOptionalFeature -Online -FeatureName $Id.Substring(8) -ErrorAction Stop).State}
    if($Id.StartsWith('ServiceDependencies.')){return ((Get-Service -Name $Id.Substring(20) -ErrorAction Stop).ServicesDependedOn.Name|Sort-Object)-join '/'}
    if($Id.StartsWith('Accessibility.')){return Invoke-WinriftSystemParameters -Setting $Id.Substring(14)}
    if($Id -eq 'MenuDelay'){return Invoke-WinriftSystemParameters -Setting MenuDelay}
    if ($Id.StartsWith('Service.')) {
        $name = $Id.Substring(8)
        $service = Get-Service -Name $name -ErrorAction Stop
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
        $delayed = Get-WinriftRegistrySnapshot $key DelayedAutoStart
        $delayValue = if ($delayed.Exists) { [string]$delayed.Value } else { 'Absent' }
        return "$($service.StartType)|$($service.Status)|$delayValue"
    }
    if ($Id.StartsWith('Task.')) {
        $fullPath = $Id.Substring(5)
        if (-not $fullPath.StartsWith('\')) { $fullPath = '\' + $fullPath }
        $split = $fullPath.LastIndexOf('\')
        $path = $fullPath.Substring(0, $split + 1)
        $name = $fullPath.Substring($split + 1)
        $task = Get-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction Stop
        return [bool]$task.Settings.Enabled
    }
    if ($Id -eq 'PowerPlan') {
        $output = & powercfg.exe /getactivescheme 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $output -notmatch '[a-fA-F0-9]{8}-[a-fA-F0-9-]{27}') { throw 'Active power plan unavailable.' }
        return $Matches[0].ToLowerInvariant()
    }
    if ($Id -match '^Trim\.(NTFS|ReFS)$') {
        $filesystem = $Matches[1]
        $output = & fsutil.exe behavior query DisableDeleteNotify 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $output -notmatch "(?m)^$filesystem\s+DisableDeleteNotify\s*=\s*([01])") { throw "TRIM query unavailable: $filesystem" }
        return [int]$Matches[1]
    }
    if ($Id -eq 'LastAccess') {
        $output = & fsutil.exe behavior query DisableLastAccess 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $output -notmatch '=\s*([0-3])') { throw 'LastAccess query unavailable.' }
        return [int]$Matches[1]
    }
    if ($Id -match '^MMAgent\.(ApplicationPreLaunch|PageCombining)$') {
        $property = $Matches[1]
        $state = Get-MMAgent -ErrorAction Stop
        if ($null -eq $state.$property) { throw "MMAgent property unavailable: $property" }
        return [bool]$state.$property
    }
    throw "Unknown system action: $Id"
}

function Set-WinriftSystemValue {
    param([string]$Id, $Value)
    if($Id.StartsWith('Environment.')){[Environment]::SetEnvironmentVariable($Id.Substring(12),$Value,'Machine');return}
    if($Id.StartsWith('Feature.')){
        $name=$Id.Substring(8)
        if($Value -eq 'Enabled'){Enable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction Stop|Out-Null}
        elseif($Value -eq 'Disabled'){Disable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction Stop|Out-Null}
        else{throw 'Unsupported optional-feature state.'}
        return
    }
    if($Id.StartsWith('ServiceDependencies.')){
        $name=$Id.Substring(20);$dependencies=([string]$Value).Split('/')
        foreach($dependency in $dependencies){if($dependency){$null=Get-Service -Name $dependency -ErrorAction Stop}}
        & sc.exe config $name 'depend=' ([string]$Value)|Out-Null
        if($LASTEXITCODE -ne 0){throw "Service dependency configuration failed: $LASTEXITCODE"}
        return
    }
    if($Id.StartsWith('Accessibility.')){Invoke-WinriftSystemParameters -Setting $Id.Substring(14) -Value ([int]$Value) -Set;return}
    if($Id -eq 'MenuDelay'){Invoke-WinriftSystemParameters -Setting MenuDelay -Value ([int]$Value) -Set;return}
    if ($Id.StartsWith('Service.')) {
        $name = $Id.Substring(8)
        $parts = ([string]$Value).Split('|')
        if ($parts.Count -ne 3 -or $parts[0] -notin @('Automatic','Manual','Disabled') -or $parts[1] -notin @('Running','Stopped','Paused')) { throw 'Unsupported service state.' }
        Set-Service -Name $name -StartupType $parts[0] -ErrorAction Stop
        $key="HKLM:\SYSTEM\CurrentControlSet\Services\$name"
        if ($parts[2] -eq 'Absent') { Remove-ItemProperty -LiteralPath $key -Name DelayedAutoStart -ErrorAction SilentlyContinue }
        else { Set-ItemProperty -LiteralPath $key -Name DelayedAutoStart -Type DWord -Value ([int]$parts[2]) -ErrorAction Stop }
        if ($parts[1] -eq 'Stopped') { Stop-Service -Name $name -Force -ErrorAction Stop }
        elseif ($parts[1] -eq 'Running') { Start-Service -Name $name -ErrorAction Stop }
        else { if ((Get-Service -Name $name).Status -eq 'Stopped') { Start-Service -Name $name -ErrorAction Stop }; Suspend-Service -Name $name -ErrorAction Stop }
        return
    }
    if ($Id.StartsWith('Task.')) {
        $fullPath=$Id.Substring(5); if (-not $fullPath.StartsWith('\')) { $fullPath='\'+$fullPath }; $split=$fullPath.LastIndexOf('\')
        $path=$fullPath.Substring(0,$split+1); $name=$fullPath.Substring($split+1)
        if ([bool]$Value) { Enable-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction Stop | Out-Null }
        else { Disable-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction Stop | Out-Null }
        return
    }
    if ($Id -eq 'PowerPlan') {
        if ("$Value" -notmatch '^[a-fA-F0-9]{8}-[a-fA-F0-9-]{27}$') { throw 'Invalid power plan identifier.' }
        & powercfg.exe /setactive $Value | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Power plan activation failed.' }
        return
    }
    if ($Id -match '^Trim\.(NTFS|ReFS)$') {
        $output = & fsutil.exe behavior set DisableDeleteNotify $Matches[1] ([int]$Value) 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw $output }
        return
    }
    if ($Id -eq 'LastAccess') {
        $output = & fsutil.exe behavior set DisableLastAccess ([int]$Value) 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw $output }
        return
    }
    if ($Id -match '^MMAgent\.(ApplicationPreLaunch|PageCombining)$') {
        $arguments = @{ $Matches[1] = $true; ErrorAction = 'Stop' }
        if ([bool]$Value) { Enable-MMAgent @arguments } else { Disable-MMAgent @arguments }
        return
    }
    throw "Unknown system action: $Id"
}

function Add-WinriftSystemAction {
    param([string]$Id, $Value, [string]$Message)
    try {
        $current = Get-WinriftSystemValue $Id
        $entry = @{ Kind='System'; Id=$Id; Value=$Value; Current=$current; Message=$Message; Type='System'; Name=$Id; Supported=$true }
    } catch {
        $entry = @{ Kind='System'; Id=$Id; Value=$Value; Current='Unavailable'; Message=$Message; Type='System'; Name=$Id; Supported=$false; Reason=$_.Exception.Message }
    }
    if ($script:CollectMode) { $script:AuditQueue.Add($entry) }
    elseif ($entry.Supported) { Invoke-WinriftSystemAction $entry }
    else {
        $script:LastActionResult = @{ Status = 'Unsupported'; Error = $entry.Reason }
        Write-Log "$Message unavailable: $($entry.Reason)" -Level WARNING
    }
}

function Invoke-WinriftSystemAction {
    param($Entry)
    $script:LastActionResult=@{Status='Pending';Error=$null}
    if (-not $Entry.Supported) { $script:LastActionResult.Status='Unsupported';return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { $script:LastActionResult.Status='DryRun';Write-Log "[DRY-RUN] $($Entry.Message)"; return }
    $record = $null
    try {
        $current = Get-WinriftSystemValue $Entry.Id
        if ("$current" -eq "$($Entry.Value)") { $script:LastActionResult.Status='AlreadyMatches'; Write-Log "Already matches: $($Entry.Message)" -Level SKIP; return }
        $record = New-WinriftActionRecord -Kind System -Label $Entry.Message -Target @{ Id=$Entry.Id } -Before $current -Proposed $Entry.Value
        Save-WinriftActionRecord $record
        Set-WinriftSystemValue $Entry.Id $Entry.Value
        $after = Get-WinriftSystemValue $Entry.Id
        if ("$after" -ne "$($Entry.Value)") { throw 'Effective configuration query did not match the proposed state.' }
        $script:LastActionResult.Status='Applied'
        $record.status = 'Applied'
        $record.verification = 'Effective configuration queried; performance and driver effect not measured.'
        Save-WinriftActionRecord $record
        Write-Log "$($Entry.Message) — configuration verified." -Level SUCCESS
    } catch {
        $script:LastActionResult=@{Status='Failed';Error=$_.Exception.Message}
        if ($null -ne $record) { $record.status='Failed'; $record.error=$script:LastActionResult.Error; try { $record.observed=Get-WinriftSystemValue $Entry.Id } catch {}; try { Save-WinriftActionRecord $record } catch { Write-Warning 'Pending action journal preserved; finalization failed.' } }
        Write-Log "$($Entry.Message) failed: $($_.Exception.Message)" -Level ERROR
    }
}

function Restore-WinriftSystemAction {
    param($Record)
    $current = Get-WinriftSystemValue $Record.target.Id
    if ("$current" -eq "$($Record.before)") { return 'AlreadyRestored' }
    $expected=if($Record.status -eq 'Failed' -and $null -ne $Record.observed){$Record.observed}else{$Record.proposed}
    if ("$current" -ne "$expected") { return 'Conflict' }
    if ($env:WINRIFT_DRY_RUN -eq '1') { return 'DryRun' }
    Set-WinriftSystemValue $Record.target.Id $Record.before
    if ("$(Get-WinriftSystemValue $Record.target.Id)" -ne "$($Record.before)") { throw 'Previous effective state could not be verified.' }
    $Record.status='Undone'; $Record.verification='Previous effective configuration queried.'
    Save-WinriftActionRecord $Record
    return 'Restored'
}

function Test-WinriftQueuedChange {
    param($Entry)
    if ($Entry.Kind -eq 'System') { return $Entry.Supported -and "$($Entry.Current)" -ne "$($Entry.Value)" }
    return -not (Test-WinriftRegistrySnapshot $Entry.CurrentSnapshot @{ Exists=$true; Type=$Entry.Type; Value=$Entry.Value })
}