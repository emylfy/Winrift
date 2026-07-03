BeforeAll {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $repoRoot 'modules/iso/ISOBuilder.ps1')
    $script:answerFile = Join-Path $repoRoot 'config/autounattend.xml'
    $script:profileFile = Join-Path $repoRoot 'config/profiles/example.json'

    $script:unattendNs = 'urn:schemas-microsoft-com:unattend'
    $script:schneegansNs = 'https://schneegans.de/windows/unattend-generator/'
}

Describe 'Add-WinriftProfileToAnswerFile' {
    BeforeEach {
        $script:workXml = Join-Path $TestDrive 'autounattend.xml'
        Copy-Item $script:answerFile $script:workXml -Force
    }

    It 'embeds the profile and apply bootstrap as schneegans File elements' {
        Add-WinriftProfileToAnswerFile -XmlPath $script:workXml -ProfilePath $script:profileFile

        [xml]$out = Get-Content $script:workXml -Raw
        $ns = New-Object System.Xml.XmlNamespaceManager($out.NameTable)
        $ns.AddNamespace('s', $script:schneegansNs)

        $profileNode = $out.SelectSingleNode("//s:File[@path='C:\Windows\Setup\Scripts\winrift-profile.json']", $ns)
        $applyNode = $out.SelectSingleNode("//s:File[@path='C:\Windows\Setup\Scripts\WinriftApply.ps1']", $ns)

        $profileNode | Should -Not -BeNullOrEmpty
        $applyNode | Should -Not -BeNullOrEmpty
        ($profileNode.InnerText | ConvertFrom-Json).name | Should -Be 'example'
        $applyNode.InnerText | Should -Match 'apply\.ps1'
        $applyNode.InnerText | Should -Match 'WINRIFT_PROFILE'
    }

    It 'appends a FirstLogon command in every component' {
        Add-WinriftProfileToAnswerFile -XmlPath $script:workXml -ProfilePath $script:profileFile

        [xml]$out = Get-Content $script:workXml -Raw
        $ns = New-Object System.Xml.XmlNamespaceManager($out.NameTable)
        $ns.AddNamespace('u', $script:unattendNs)

        $flcNodes = $out.SelectNodes('//u:FirstLogonCommands', $ns)
        $flcNodes.Count | Should -BeGreaterThan 0
        foreach ($flc in $flcNodes) {
            $applyCmd = $flc.SelectNodes('u:SynchronousCommand', $ns) |
                Where-Object { $_.SelectSingleNode('u:CommandLine', $ns).InnerText -match 'WinriftApply\.ps1' }
            $applyCmd | Should -Not -BeNullOrEmpty
        }
    }

    It 'produces a well-formed answer file that still parses' {
        Add-WinriftProfileToAnswerFile -XmlPath $script:workXml -ProfilePath $script:profileFile
        { [xml](Get-Content $script:workXml -Raw) } | Should -Not -Throw
    }

    It 'throws on a non-schneegans answer file' {
        $plain = Join-Path $TestDrive 'plain.xml'
        Set-Content -Path $plain -Value '<?xml version="1.0"?><unattend xmlns="urn:schemas-microsoft-com:unattend"></unattend>'
        { Add-WinriftProfileToAnswerFile -XmlPath $plain -ProfilePath $script:profileFile } | Should -Throw
    }

    It 'throws on an invalid profile' {
        $bad = Join-Path $TestDrive 'bad.json'
        Set-Content -Path $bad -Value '{ not json'
        { Add-WinriftProfileToAnswerFile -XmlPath $script:workXml -ProfilePath $bad } | Should -Throw
    }
}
