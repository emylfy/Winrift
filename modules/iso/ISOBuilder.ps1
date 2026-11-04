$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$scriptRoot\scripts\Common.ps1"
Initialize-Logging -ModuleName "isobuilder"

$OSCDIMG_URL = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"
$OSCDIMG_SHA256 = "F5129F313ED7EB46F2677CF522E64264A225F226307ED0DDB52BB14C46E7CFDD"
$ADK_PAGE = "https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install"

function Get-OscdimgPath {
    # 1. Check Windows ADK installation
    if ([Environment]::Is64BitOperatingSystem) { $arch = "amd64" } else { $arch = "x86" }
    $kitsRoot = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots" -Name KitsRoot10 -ErrorAction SilentlyContinue).KitsRoot10
    if ($kitsRoot) {
        $adkPath = Join-Path $kitsRoot "Assessment and Deployment Kit\Deployment Tools\$arch\Oscdimg\oscdimg.exe"
    } else {
        $adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$arch\Oscdimg\oscdimg.exe"
    }
    if (Test-Path $adkPath) {
        Write-Log -Message "Using oscdimg.exe from system ADK." -Level INFO -LogFile $script:LogFile
        return $adkPath
    }

    # 2. Check local copy next to this script
    $localPath = Join-Path $PSScriptRoot "oscdimg.exe"
    if (Test-Path $localPath) {
        Write-Log -Message "Using local oscdimg.exe." -Level INFO -LogFile $script:LogFile
        return $localPath
    }

    # 3. Not found — ask user how to proceed
    $response = Show-InteractiveMenu -Title "oscdimg.exe not found" -Items @(
        "oscdimg.exe is required to build bootable ISOs.",
        "It is a Microsoft tool included in the Windows ADK.",
        "---",
        "Source: msdl.microsoft.com (official Symbol Server)",
        "Same source used by tiny11maker and Windows ADK tools.",
        "---",
        "Y › Download from Microsoft",
        "N › Cancel",
        "A › Open ADK download page (install manually)"
    )
    switch ($response) {
        "Y" {}
        "A" {
            Start-Process $ADK_PAGE
            Write-Log -Message "Opened ADK download page. Install ADK, then re-run ISO Builder." -Level INFO -LogFile $script:LogFile
            return $null
        }
        default { return $null }
    }

    # Download via Invoke-SecureDownload (hash verified when $OSCDIMG_SHA256 is set)
    try {
        Invoke-SecureDownload -Url $OSCDIMG_URL -OutFile $localPath -ToolName "oscdimg.exe" -ExpectedHash $OSCDIMG_SHA256
    } catch {
        Write-Log -Message "Download failed: $($_.Exception.Message)" -Level ERROR -LogFile $script:LogFile
        return $null
    }

    return $localPath
}

function Select-ISOFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    if ($dialog.ShowDialog() -eq "OK") {
        return $dialog.FileName
    }
    return $null
}

function Select-ProfileFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select a Winrift profile (.json)"
    $dialog.Filter = "Winrift profiles (*.json)|*.json"
    $defaultDir = Join-Path $scriptRoot "config\profiles"
    if (Test-Path $defaultDir) { $dialog.InitialDirectory = $defaultDir }
    if ($dialog.ShowDialog() -eq "OK") { return $dialog.FileName }
    return $null
}

function Add-WinriftProfileToAnswerFile {
    # Bakes a Winrift profile into a schneegans-style autounattend.xml so the
    # installed machine self-configures at first logon with zero clicks. Embeds
    # the profile JSON and a tiny apply bootstrap as <File> elements (extracted
    # to C:\Windows\Setup\Scripts at specialize), and appends a FirstLogon command
    # that runs the bootstrap. Returns nothing; throws on a non-schneegans file.
    param(
        [Parameter(Mandatory)][string]$XmlPath,
        [Parameter(Mandatory)][string]$ProfilePath
    )
    $unattendNs   = "urn:schemas-microsoft-com:unattend"
    $wcmNs        = "http://schemas.microsoft.com/WMIConfig/2002/State"
    $schneegansNs = "https://schneegans.de/windows/unattend-generator/"

    # Validate the profile is real JSON before embedding it into the image.
    $profileJson = Get-Content $ProfilePath -Raw
    $null = $profileJson | ConvertFrom-Json

    [xml]$xml = Get-Content $XmlPath -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("u", $unattendNs)
    $ns.AddNamespace("wcm", $wcmNs)
    $ns.AddNamespace("s", $schneegansNs)

    $ext = $xml.SelectSingleNode("//s:Extensions", $ns)
    if (-not $ext) { throw "Answer file has no schneegans <Extensions> block — profile baking supports the built-in answer file (or one generated by schneegans.de/windows/unattend-generator)." }

    $bootstrap = @'
$env:WINRIFT_PROFILE = 'C:\Windows\Setup\Scripts\winrift-profile.json'
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/emylfy/winrift/main/scripts/apply.ps1 | iex
'@

    $newFile = {
        param($path, $content)
        $el = $xml.CreateElement("File", $schneegansNs)
        $el.SetAttribute("path", $path)
        $el.InnerText = $content
        return $el
    }
    $ext.AppendChild((& $newFile "C:\Windows\Setup\Scripts\winrift-profile.json" $profileJson)) | Out-Null
    $ext.AppendChild((& $newFile "C:\Windows\Setup\Scripts\WinriftApply.ps1" $bootstrap)) | Out-Null

    $flcNodes = $xml.SelectNodes("//u:FirstLogonCommands", $ns)
    if (-not $flcNodes -or $flcNodes.Count -eq 0) { throw "Answer file has no <FirstLogonCommands> block to hook into." }
    foreach ($flc in $flcNodes) {
        $maxOrder = 0
        foreach ($existing in $flc.SelectNodes("u:SynchronousCommand", $ns)) {
            $o = 0
            $orderNode = $existing.SelectSingleNode("u:Order", $ns)
            if ($orderNode -and [int]::TryParse($orderNode.InnerText, [ref]$o) -and $o -gt $maxOrder) { $maxOrder = $o }
        }

        $sc = $xml.CreateElement("SynchronousCommand", $unattendNs)
        $actionAttr = $xml.CreateAttribute("wcm", "action", $wcmNs)
        $actionAttr.Value = "add"
        $sc.Attributes.Append($actionAttr) | Out-Null

        $order = $xml.CreateElement("Order", $unattendNs)
        $order.InnerText = [string]($maxOrder + 1)
        $cmd = $xml.CreateElement("CommandLine", $unattendNs)
        $cmd.InnerText = 'powershell.exe -WindowStyle "Normal" -ExecutionPolicy "Unrestricted" -NoProfile -File "C:\Windows\Setup\Scripts\WinriftApply.ps1"'
        $sc.AppendChild($order) | Out-Null
        $sc.AppendChild($cmd) | Out-Null
        $flc.AppendChild($sc) | Out-Null
    }

    $xml.Save($XmlPath)
}

function Add-WinriftSavedSetupToMedia {
    param([string]$MediaRoot,[string]$SetupPath,[ValidateSet('amd64','arm64','x86')][string]$Architecture)
    . "$PSScriptRoot\..\profile\Profile.ps1"
    $setup=Read-WinriftSetup $SetupPath
    Test-WinriftSetupContent $setup
    $repository=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $payload=Join-Path $MediaRoot 'sources\$OEM$\$$\Setup\Scripts\Winrift'
    [IO.Directory]::CreateDirectory($payload)|Out-Null
    foreach($name in @('Winrift.ps1','scripts','modules','config')){Copy-Item -LiteralPath (Join-Path $repository $name) -Destination $payload -Recurse -Force -ErrorAction Stop}
    Write-WinriftAtomicJson -Path (Join-Path $payload 'setup.json') -Value $setup
    $answerPath=Join-Path $MediaRoot 'autounattend.xml'
    $xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null
    if(Test-Path -LiteralPath $answerPath){$xml.Load($answerPath)}else{$xml.LoadXml('<unattend xmlns="urn:schemas-microsoft-com:unattend" />')}
    $nsUri='urn:schemas-microsoft-com:unattend';$wcm='http://schemas.microsoft.com/WMIConfig/2002/State'
    $ns=[Xml.XmlNamespaceManager]::new($xml.NameTable);$ns.AddNamespace('u',$nsUri)
    $settings=$xml.SelectSingleNode('/u:unattend/u:settings[@pass="oobeSystem"]',$ns)
    if(-not $settings){$settings=$xml.CreateElement('settings',$nsUri);$settings.SetAttribute('pass','oobeSystem');[void]$xml.DocumentElement.AppendChild($settings)}
    $component=$settings.SelectSingleNode("u:component[@name='Microsoft-Windows-Shell-Setup' and @processorArchitecture='$Architecture']",$ns)
    if(-not $component){
        $component=$xml.CreateElement('component',$nsUri)
        foreach($pair in @{name='Microsoft-Windows-Shell-Setup';processorArchitecture=$Architecture;publicKeyToken='31bf3856ad364e35';language='neutral';versionScope='nonSxS'}.GetEnumerator()){$component.SetAttribute($pair.Key,$pair.Value)}
        [void]$settings.AppendChild($component)
    }
    $commands=$component.SelectSingleNode('u:FirstLogonCommands',$ns)
    if(-not $commands){$commands=$xml.CreateElement('FirstLogonCommands',$nsUri);[void]$component.AppendChild($commands)}
    $maximum=0
    foreach($order in $commands.SelectNodes('u:SynchronousCommand/u:Order',$ns)){$number=0;if([int]::TryParse($order.InnerText,[ref]$number)){$maximum=[math]::Max($maximum,$number)}}
    $command=$xml.CreateElement('SynchronousCommand',$nsUri);$command.SetAttribute('action',$wcm,'add')
    $order=$xml.CreateElement('Order',$nsUri);$order.InnerText=[string]($maximum+1);[void]$command.AppendChild($order)
    $line=$xml.CreateElement('CommandLine',$nsUri)
    $line.InnerText='cmd.exe /d /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%WINDIR%\Setup\Scripts\Winrift\Winrift.ps1" -Apply "%WINDIR%\Setup\Scripts\Winrift\setup.json" -NoConfirm'
    [void]$command.AppendChild($line);[void]$commands.AppendChild($command)
    $xml.Save($answerPath)
}

function Build-WinriftISO {
    param([Parameter(Mandatory)][string]$ISOPath,[string]$AnswerFile,[string]$SetupPath,[Parameter(Mandatory)][string]$OutputPath)
    if(-not(Test-Path -LiteralPath $ISOPath -PathType Leaf)){throw 'Select an existing Windows ISO.'}
    if(Test-Path -LiteralPath $OutputPath){throw 'The output file already exists. Choose a new output path.'}
    if($SetupPath){. "$PSScriptRoot\..\profile\Profile.ps1";$setup=Read-WinriftSetup $SetupPath;Test-WinriftSetupContent $setup}
    if($AnswerFile){$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($AnswerFile)}
    if($env:WINRIFT_DRY_RUN -eq '1'){Write-Log "[DRY-RUN] Build $ISOPath -> $OutputPath; answer file: $AnswerFile; saved setup: $SetupPath";return}
    $oscdimg=Get-OscdimgPath
    if(-not $oscdimg){return}
    $scratchParent=Join-Path ([IO.Path]::GetTempPath()) 'Winrift'
    $scratch=Join-Path $scratchParent ('iso-'+[guid]::NewGuid().ToString('N'))
    $mountedHere=$false
    try{
        [IO.Directory]::CreateDirectory($scratch)|Out-Null
        $image=Get-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue
        if(-not $image -or -not $image.Attached){$image=Mount-DiskImage -ImagePath $ISOPath -PassThru -ErrorAction Stop;$mountedHere=$true}
        $volume=$image|Get-Volume|Select-Object -First 1
        if(-not $volume.DriveLetter){throw 'Mounted ISO has no accessible volume.'}
        $drive="$($volume.DriveLetter):\"
        $install=Join-Path $drive 'sources\install.wim'
        if(-not(Test-Path -LiteralPath $install)){$install=Join-Path $drive 'sources\install.esd'}
        if(-not(Test-Path -LiteralPath $install)){throw 'The ISO contains no Windows install.wim or install.esd.'}
        $imageInfo=Get-WindowsImage -ImagePath $install -Index 1 -ErrorAction Stop
        $architecture=switch([int]$imageInfo.Architecture){9{'amd64'}12{'arm64'}0{'x86'}default{throw 'Unsupported image architecture.'}}
        Get-ChildItem -LiteralPath $drive -Force|Copy-Item -Destination $scratch -Recurse -Force -ErrorAction Stop
        if($AnswerFile){Copy-Item -LiteralPath $AnswerFile -Destination (Join-Path $scratch 'autounattend.xml') -Force -ErrorAction Stop}
        if($SetupPath){Add-WinriftSavedSetupToMedia -MediaRoot $scratch -SetupPath $SetupPath -Architecture $architecture}
        $bios=Join-Path $scratch 'boot\etfsboot.com';$efi=Join-Path $scratch 'efi\microsoft\boot\efisys.bin'
        if(-not(Test-Path -LiteralPath $efi)){throw 'UEFI boot image is missing; refusing to produce an unverified boot layout.'}
        $boot=if(Test-Path -LiteralPath $bios){"-bootdata:2#p0,e,b`"$bios`"#pEF,e,b`"$efi`""}else{"-bootdata:1#pEF,e,b`"$efi`""}
        $PSNativeCommandArgumentPassing='Legacy'
        & $oscdimg '-m' '-o' '-u2' '-udfver102' $boot $scratch $OutputPath
        if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $OutputPath)){throw "oscdimg failed (exit code $LASTEXITCODE)."}
        Write-Log "ISO file created: $OutputPath. Boot/install cycle has not been verified." -Level SUCCESS
    }finally{
        if($mountedHere){Dismount-DiskImage -ImagePath $ISOPath -ErrorAction SilentlyContinue|Out-Null}
        $resolved=[IO.Path]::GetFullPath($scratch);$boundary=[IO.Path]::GetFullPath($scratchParent).TrimEnd('\')+'\'
        if($resolved.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
    }
}

function Show-WinriftMediaMenu {
    $media=@{ISOPath=$null;AnswerFile=$null;SetupPath=$null;OutputPath=$null}
    Invoke-MenuLoop -Title 'Create Windows Installation Media' -Items @(
        '1 › Select Windows ISO               ›','2 › Windows Installation Options     ›',
        '3 › Include Saved Setup              ›','4 › Review & Build                   ›','---','0 › Back'
    ) -Actions @{
        '1'={$path=Select-ISOFile;if($path){$media.ISOPath=$path}}
        '2'={
            $choice=Show-InteractiveMenu -Title 'Windows Installation Options' -Items @('S › Standard interactive Windows Setup','C › Choose a custom answer file','---','B › Back')
            if($choice -eq 'S'){$media.AnswerFile=$null}
            elseif($choice -eq 'C'){$path=Read-Host 'Custom autounattend.xml (full path)';if($path){$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($path);$media.AnswerFile=$path}}
        }
        '3'={
            $choice=Show-InteractiveMenu -Title 'Include Saved Setup' -Items @('Y › Choose a saved setup','N › Do not include a setup','B › Back')
            if($choice -eq 'N'){$media.SetupPath=$null}
            elseif($choice -eq 'Y'){
                $path=Select-ProfileFile
                if($path){. "$PSScriptRoot\..\profile\Profile.ps1";$setup=Read-WinriftSetup $path;Test-WinriftSetupContent $setup;$media.SetupPath=$path}
            }
        }
        '4'={
            if(-not $media.ISOPath){Write-Log 'Select Windows ISO first.';Wait-ForUser;return}
            $path=Read-Host 'New output ISO file (full path)'
            if(-not $path){return};$media.OutputPath=$path
            $rows=@("Source ISO: $($media.ISOPath)","Output: $path",$(if($media.AnswerFile){"Custom installation options: $($media.AnswerFile)"}else{'Standard interactive Windows installation.'}))
            if($media.SetupPath){. "$PSScriptRoot\..\profile\Profile.ps1";$setup=Read-WinriftSetup $media.SetupPath;$rows+=@(Get-WinriftSetupPreview $setup @('Windows','Apps','Configurations'));$rows+='The saved setup applies at first logon using the included Winrift code. App/PowerShell downloads may require network access.'}
            $rows+='Full installation validation remains separate from ISO creation.'
            $choice=Show-InteractiveMenu -Title 'Review & Build' -Items ($rows+@('---','Y › Build ISO','N › Back'))
            if($choice -eq 'Y'){try{Build-WinriftISO @media}catch{Write-Log "ISO build failed: $($_.Exception.Message)" -Level ERROR};Wait-ForUser}
        }
    } -ExitKey '0' -HideKeys
}

if($MyInvocation.InvocationName -ne '.'){Show-WinriftMediaMenu}
