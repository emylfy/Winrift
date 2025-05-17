# . "$PSScriptRoot\AdminLaunch.ps1"

function Start-AdminProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )
    $useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue
    
		$psArguments = ""
    if ($NoExit) {
        $psArguments += "-NoExit "
    }
    
		$psArguments += "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"
    if ($useWindowsTerminal) {
        $wtArguments = "powershell $psArguments"
        Start-Process -FilePath "wt.exe" -ArgumentList $wtArguments -Verb RunAs
    } else {
        Start-Process -FilePath "powershell.exe" -ArgumentList $psArguments -Verb RunAs
    }
}
