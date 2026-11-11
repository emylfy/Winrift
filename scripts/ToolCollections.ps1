function Get-WinriftToolCollectionUri {
    param([string]$Value)

    $uri = $null
    if (-not [uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne 'https' -or $uri.UserInfo -or $Value -match '[\p{C}\p{Z}]') {
        throw 'Enter a valid HTTPS link.'
    }
    return $uri
}

function Get-WinriftToolCollectionText {
    param([uri]$Uri)

    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false
    $client = [Net.Http.HttpClient]::new($handler)
    try {
        $client.Timeout = [TimeSpan]::FromSeconds(15)
        $client.MaxResponseContentBufferSize = 256KB
        $client.DefaultRequestHeaders.UserAgent.ParseAdd('Winrift')
        return $client.GetStringAsync($Uri).GetAwaiter().GetResult()
    } finally {
        $client.Dispose()
    }
}

function ConvertTo-WinriftToolCollection {
    param([System.Collections.IDictionary]$Catalog)

    if ($Catalog.schemaVersion -isnot [long] -and $Catalog.schemaVersion -isnot [int]) {
        throw 'A collection must declare schemaVersion 1.'
    }
    if ($Catalog.schemaVersion -ne 1 -or $Catalog.name -isnot [string] -or
        $Catalog.name -notmatch '^[^\p{C}›↗~]{1,60}$' -or -not $Catalog.name.Trim() -or
        $Catalog.tools -isnot [array] -or $Catalog.tools.Count -notin (1..30)) {
        throw 'Expected schemaVersion 1, a collection name and 1–30 tools.'
    }

    $names = @{}
    $tools = foreach ($tool in $Catalog.tools) {
        if ($tool -isnot [System.Collections.IDictionary] -or
            $tool.name -isnot [string] -or $tool.name -notmatch '^[^\p{C}›↗~]{1,60}$' -or
            -not $tool.name.Trim() -or $names.ContainsKey($tool.name.Trim()) -or
            $tool.type -isnot [string] -or $tool.type -cnotin @('url', 'file', 'powershell') -or
            $tool.target -isnot [string] -or $tool.target -notmatch '^[^\p{C}]{1,4096}$' -or -not $tool.target.Trim()) {
            throw 'Each tool needs a unique name, a supported type and a single-line target.'
        }
        if ($tool.Contains('description') -and
            ($tool.description -isnot [string] -or $tool.description -notmatch '^[^\p{C}]{0,240}$')) {
            throw 'A tool description must be a single line of up to 240 characters.'
        }
        $names[$tool.name.Trim()] = $true
        $target = $tool.target.Trim()
        if ($tool.type -eq 'url') { $target = (Get-WinriftToolCollectionUri $target).AbsoluteUri }
        if ($tool.type -eq 'file' -and
            ($target -notmatch '^[A-Za-z]:[\\/]' -or [IO.Path]::GetExtension($target) -notin @('.exe', '.ps1'))) {
            throw 'A file target must be an absolute Windows path to an .exe or .ps1.'
        }
        [ordered]@{ name = $tool.name.Trim(); description = ([string]$tool.description).Trim(); type = $tool.type; target = $target }
    }
    return [ordered]@{ schemaVersion = 1; name = $Catalog.name.Trim(); tools = @($tools) }
}

function Import-WinriftToolCollection {
    param([uri]$Source)

    $uri = Get-WinriftToolCollectionUri $Source.AbsoluteUri
    if ($Source.Host -eq 'gist.github.com') {
        if (-not $Source.IsDefaultPort -or
            $Source.AbsolutePath -notmatch '^/(?:(?<id>[0-9a-f]+)|[\w-]+/(?<id>[0-9a-f]+)(?:/(?<revision>[0-9a-f]{40}))?)/?$') {
            throw 'Enter a GitHub Gist link or a direct JSON link.'
        }
        $api = 'https://api.github.com/gists/' + $Matches.id
        if ($Matches.revision) { $api += '/' + $Matches.revision }
        $gistText = Get-WinriftToolCollectionText ([uri]$api)
        try { $gist = ConvertFrom-Json -InputObject $gistText -AsHashtable -NoEnumerate -ErrorAction Stop }
        catch { throw 'GitHub returned an invalid Gist response.' }
        $file = $gist.files['tools.json']
        if (-not $file) { throw 'This Gist does not contain tools.json.' }
        $uri = Get-WinriftToolCollectionUri $file.raw_url
        if ($uri.Host -ne 'gist.githubusercontent.com') { throw 'Unexpected GitHub Gist file host.' }
    }
    $catalogText = Get-WinriftToolCollectionText $uri
    try { $catalog = ConvertFrom-Json -InputObject $catalogText -AsHashtable -NoEnumerate -ErrorAction Stop }
    catch { throw 'The collection is not valid JSON.' }
    if ($catalog -isnot [System.Collections.IDictionary]) { throw 'The collection must be a JSON object.' }
    return ConvertTo-WinriftToolCollection $catalog
}

function Get-WinriftToolCollectionPath {
    param([uri]$Source)

    $key = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($Source.AbsoluteUri)))
    return Join-Path (Get-WinriftStateRoot) "tool-collections\$key.json"
}

function Show-WinriftToolCollectionImport {
    param([uri]$Source, $Previous)

    if ($null -eq $Source) {
        $link = Read-Host 'Collection HTTPS link'
        if (-not $link.Trim()) { return }
        $Source = Get-WinriftToolCollectionUri $link.Trim()
    }
    $path = Get-WinriftToolCollectionPath $Source
    if (-not $Previous -and [IO.File]::Exists($path)) {
        $Previous = Read-WinriftJson $path -AsHashtable
    }

    $catalog = Import-WinriftToolCollection $Source
    $items = @("Source $($Source.AbsoluteUri)", '---')
    if ($Previous) {
        if ($Previous.catalog.name -cne $catalog.name) { $items += "Renamed from $($Previous.catalog.name)" }
        $old = @{}
        foreach ($tool in $Previous.catalog.tools) { $old[$tool.name] = $tool }
        foreach ($tool in $catalog.tools) {
            $previousTool = $old[$tool.name]
            if (-not $previousTool) { $items += "Added: $($tool.name)" }
            elseif ($previousTool.type -cne $tool.type -or $previousTool.target -cne $tool.target -or
                [string]$previousTool.description -cne $tool.description) {
                $items += "Changed: $($tool.name)"
            }
            $old.Remove($tool.name)
        }
        foreach ($name in ($old.Keys | Sort-Object)) { $items += "Removed: $name" }
        if ($items.Count -eq 2) { $items += 'No tool changes.' }
        $label = 'Save Update'
    } else {
        $items += @($catalog.tools | ForEach-Object { "Tool: $($_.name)" })
        $label = 'Add Collection'
    }
    $choice = Show-InteractiveMenu -Title $catalog.name -Items ($items + @('---', "A › $label", 'N › Back'))
    if ($choice -ne 'A') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { return }
    Write-WinriftAtomicJson -Path $path -Value @{ schemaVersion = 1; source = $Source.AbsoluteUri; catalog = $catalog }
}

function Start-WinriftCollectionTool {
    param($Tool, [string]$Source)

    Clear-Host
    Write-Host $Tool.name
    if ($Tool.description) { Write-Host $Tool.description }
    Write-Host "Collection source: $Source"
    Write-Host ''
    Write-Host $Tool.target
    Write-Host ''
    if ($Tool.type -ne 'url') {
        Write-Host 'This tool will run with administrator rights.' -ForegroundColor Yellow
    }
    if ((Read-Host 'Type Y to continue') -ne 'Y') { return }
    if ($env:WINRIFT_DRY_RUN -eq '1') { return }
    if ($Tool.type -eq 'url') {
        Start-Process -FilePath (Get-WinriftToolCollectionUri $Tool.target).AbsoluteUri -ErrorAction Stop
        return
    }

    $process = [Diagnostics.ProcessStartInfo]::new()
    $process.UseShellExecute = $false
    $process.CreateNoWindow = $false
    if ($Tool.type -eq 'file' -and -not [IO.File]::Exists($Tool.target)) {
        throw "File not found: $($Tool.target)"
    }
    if ($Tool.type -eq 'file' -and [IO.Path]::GetExtension($Tool.target) -eq '.exe') {
        $process.FileName = $Tool.target
    } else {
        $process.FileName = Join-Path $PSHOME 'pwsh.exe'
        $process.ArgumentList.Add('-NoProfile')
        if ($Tool.type -eq 'powershell') {
            $process.ArgumentList.Add('-EncodedCommand')
            $process.ArgumentList.Add([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Tool.target)))
        } else {
            $process.ArgumentList.Add('-File')
            $process.ArgumentList.Add($Tool.target)
        }
    }
    # Keep interactive console tools usable and wait before redrawing Winrift.
    $child = [Diagnostics.Process]::Start($process)
    try {
        $child.WaitForExit()
        if ($child.ExitCode -ne 0) { throw "Tool exited with code $($child.ExitCode)." }
    } finally {
        $child.Dispose()
    }
}

function Show-WinriftToolCollection {
    param([string]$Path)

    while ([IO.File]::Exists($Path)) {
        $saved = Read-WinriftJson $Path -AsHashtable
        $catalog = ConvertTo-WinriftToolCollection $saved.catalog
        $descriptions = @{}
        $items = @(for ($i = 0; $i -lt $catalog.tools.Count; $i++) {
            $tool = $catalog.tools[$i]
            if ($tool.description) { $descriptions[$i] = $tool.description }
            "$($i + 1) › $($tool.name) ↗"
        })
        $choice = Show-InteractiveMenu -Title $catalog.name -Items ($items + @(
            '---', 'U › Update Collection', 'R › Remove Collection', '0 › Back')) -HideKeys -FocusedDescriptions $descriptions
        switch ($choice) {
            'U' { Show-WinriftToolCollectionImport -Source ([uri]$saved.source) -Previous $saved }
            'R' {
                $confirm = Show-InteractiveMenu -Title 'Remove Collection' -Items @($catalog.name, '---', 'R › Remove', 'N › Back')
                if ($confirm -eq 'R' -and $env:WINRIFT_DRY_RUN -ne '1') {
                    [IO.File]::Delete("$Path.previous")
                    [IO.File]::Delete($Path)
                }
            }
            { $_ -match '^[1-9][0-9]?$' } { Start-WinriftCollectionTool $catalog.tools[[int]$choice - 1] $saved.source }
            default { return }
        }
    }
}

function Show-WinriftAddToolCollection {
    $configPath = Join-Path $PSScriptRoot '..\config\tools.json'
    $author = (Get-Content -LiteralPath $configPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).authorCollectionUrl
    $items = @()
    if ($author) { $items += "B › Browse the Author’s Collection ↗" }
    $items += @('A › Add from a Link', '0 › Back')
    $choice = Show-InteractiveMenu -Title 'Add a Tool Collection' -Items $items -HideKeys
    if ($choice -eq 'B' -and $env:WINRIFT_DRY_RUN -ne '1') {
        Start-Process -FilePath (Get-WinriftToolCollectionUri $author).AbsoluteUri -ErrorAction Stop
    }
    if ($choice -eq 'A') { Show-WinriftToolCollectionImport }
}
