. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "DefendNot - Disable Windows Defender"

function Show-DefendNotMenu {
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   DefendNot - Disable Windows Defender via WSC API     $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Launch DefendNot                                    $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Open documentation / project source                 $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [3] Return to Menu                                      $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { 
            Write-Host ""
            Write-Host "$Yellow Warning: Windows Defender may flag this tool.$Reset"
            Write-Host "$Yellow You may need to temporarily disable real-time and tamper protection.$Reset"
            Write-Host "$Green Installing DefendNot...$Reset"
            try {
                irm https://dnot.sh/ | iex
                Write-Host "$Green DefendNot installed successfully.$Reset"
            } catch {
                Write-Host "$Red Failed to install DefendNot: $($_.Exception.Message)$Reset"
            }
            Read-Host "Press Enter to continue"
            Show-DefendNotMenu
        }
        "2" { Start-Process "https://github.com/es3n1n/defendnot"; Show-DefendNotMenu }
        "3" { return }
        default { Show-DefendNotMenu }
    }
}

Show-DefendNotMenu
