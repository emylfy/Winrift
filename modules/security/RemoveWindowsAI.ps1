. "$PSScriptRoot\..\..\scripts\Common.ps1"
$Host.UI.RawUI.WindowTitle = "RemoveWindowsAI - Remove Windows AI Features"

function Show-RemoveWindowsAIMenu {
    Clear-Host
    Write-Host
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Purple   RemoveWindowsAI - Remove Copilot, Recall & More      $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [1] Launch RemoveWindowsAI                             $Purple'$Reset"
    Write-Host "$Purple '$Reset [2] Open documentation / project source                $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    Write-Host "$Purple '$Reset [3] Back to Menu                                       $Purple'$Reset"
    Write-Host "$Purple +--------------------------------------------------------+$Reset"
    
    $choice = Read-Host ">"
    
    switch ($choice) {
        "1" { 
            Clear-Host
            try {
                & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1")))
            } catch {
                Write-Host "$Red Failed to launch RemoveWindowsAI: $($_.Exception.Message)$Reset"
                Read-Host "Press Enter to continue"
            }
            Show-RemoveWindowsAIMenu
        }
        "2" { Start-Process "https://github.com/zoicware/RemoveWindowsAI"; Show-RemoveWindowsAIMenu }
        "3" { & "$PSScriptRoot\SecurityMenu.ps1" }
        default { Show-RemoveWindowsAIMenu }
    }
}

Show-RemoveWindowsAIMenu
