Describe 'ExternalLauncher.ps1' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $scriptPath = Join-Path $repoRoot 'modules' 'tools' 'ExternalLauncher.ps1'
    }

    It 'parses without errors' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath, [ref]$null, [ref]$errors
        ) | Out-Null
        $errors | Should -HaveCount 0
    }

    It 'has a mandatory ToolId parameter' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath, [ref]$null, [ref]$null
        )
        $params = $ast.ParamBlock.Parameters
        $toolIdParam = $params | Where-Object { $_.Name.VariablePath.UserPath -eq 'ToolId' }
        $toolIdParam | Should -Not -BeNullOrEmpty

        $mandatoryAttr = $toolIdParam.Attributes | Where-Object {
            $_ -is [System.Management.Automation.Language.AttributeAst] -and
            $_.TypeName.Name -eq 'Parameter'
        }
        $mandatoryAttr | Should -Not -BeNullOrEmpty
        $mandatoryAttr.NamedArguments | Where-Object {
            $_.ArgumentName -eq 'Mandatory'
        } | Should -Not -BeNullOrEmpty
    }

    It 'ToolId parameter is typed as string' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath, [ref]$null, [ref]$null
        )
        $params = $ast.ParamBlock.Parameters
        $toolIdParam = $params | Where-Object { $_.Name.VariablePath.UserPath -eq 'ToolId' }
        $typeAttr = $toolIdParam.Attributes | Where-Object {
            $_ -is [System.Management.Automation.Language.TypeConstraintAst]
        }
        $typeAttr.TypeName.Name | Should -Be 'string'
    }

    It 'references tools.json for configuration' {
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'tools\.json'
    }

    It 'delegates tool dispatch to Invoke-Tool' {
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'Invoke-Tool'
    }
}
