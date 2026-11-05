. "$PSScriptRoot\..\..\scripts\Common.ps1"
Initialize-Logging -ModuleName unigetui

. "$PSScriptRoot\Apps.Catalog.ps1"
. "$PSScriptRoot\UniGetUI.ps1"
if ($MyInvocation.InvocationName -ne '.') { Show-AppCategoryMenu }
