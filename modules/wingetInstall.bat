:: Why is there two :wingetInstall

@echo off
setlocal EnableDelayedExpansion
net session >nul 2>&1 || (powershell start -verb runas '%~0' & exit)

:: Define colors
set cRosewater=[38;5;224m
set cFlamingo=[38;5;210m
set cMauve=[38;5;141m
set cRed=[38;5;203m
set cGreen=[38;5;120m
set cTeal=[38;5;116m
set cSky=[38;5;111m
set cSapphire=[38;5;69m
set cBlue=[38;5;75m
set cGrey=[38;5;250m
set cReset=[0m

:wingetInstallMenu
cls
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% Select Manager:                                        %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve% '%cGrey% [1] Winget - Windows native solution (CLI)             %cMauve%'%cReset%
echo %cMauve% '%cGrey% [2] UniGetUI - Graphical package manager               %cMauve%'%cReset%
echo %cMauve% '%cGrey% [3] Back to Main Menu                                  %cMauve%'%cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

choice /C 123 /N /M ">"
set /a "pkg_choice=%errorlevel%"
if !pkg_choice! equ 3 goto main
if !pkg_choice! equ 2 goto UniGetUI
if !pkg_choice! equ 1 goto checkWinget

:UniGetUI
powershell -Command "if ((winget list --id MartiCliment.UniGetUI --accept-source-agreements) -match 'MartiCliment.UniGetUI') { exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo %cGrey%UniGetUI is already installed. Launching...%cReset%
    start "" "unigetui:"
) else (
    echo %cGrey%Installing UniGetUI...%cReset%
    winget install MartiCliment.UniGetUI --accept-package-agreements --accept-source-agreements
    if !errorlevel! equ 0 (
        echo %cGreen%Successfully installed UniGetUI.%cReset%
        start "" "unigetui:"
    ) else (
        echo %cRed%Failed to install UniGetUI. Opening website for manual download...%cReset%
        start "" "https://www.marticliment.com/unigetui/"
        goto checkWinget
    )
)

goto main

:checkWinget
where winget >nul 2>nul
if !errorlevel! neq 0 (
    echo %cRed%Winget is not installed. Please install Windows App Installer from Microsoft Store.%cReset%
    start "" "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
    pause
    goto wingetInstall
)

:wingetInstall
title Simplify11: Install apps
cls

:: Define packages for winget installation
set "pkg[1]=Microsoft.VisualStudioCode"
set "pkg[2]=Python"
set "pkg[3]=OpenJS.NodeJS"
set "pkg[4]=Anysphere.Cursor"
set "pkg[5]=Git.Git"
set "pkg[6]=GitHub.GitHubDesktop"
set "pkg[7]=TheBrowserCompany.Arc"
set "pkg[8]=Alex313031.Thorium"
set "pkg[9]=Zen-Team.Zen-Browser"
set "pkg[10]=Yandex.Browser"
set "pkg[11]=Microsoft.PowerToys"
set "pkg[12]=M2Team.NanaZip"
set "pkg[13]=agalwood.motrix"
set "pkg[14]=MartiCliment.UniGetUI"
set "pkg[15]=TechPowerUp.NVCleanstall"
set "pkg[16]=NVIDIA.Broadcast"
set "pkg[17]=RadolynLabs.AyuGramDesktop"
set "pkg[18]=Vencord.Vesktop"
set "pkg[19]=lencx.ChatGPT"
set "pkg[20]=Doist.Todoist"
set "pkg[21]=RustemMussabekov.Raindrop"
set "pkg[22]=Valve.Steam"
set "pkg[23]=EpicGames.EpicGamesLauncher"
set "pkg[24]=Microsoft.DirectX"
set "pkg[25]=Microsoft.DotNet.Runtime.8"
set "pkg[26]=Microsoft.PCManager"
set "pkg[27]=Microsoft.EdgeWebView2Runtime"

echo %cMauve% +--------------------------------------------------------+%cReset%
echo %cMauve%  %cGreen%[0] Search for any program                              %cMauve% %cReset%
echo.
echo %cMauve%  %cGreen%Development Tools:                                      %cMauve% %cReset%
echo %cMauve%  %cGrey%[1] Visual Studio Code  [2] Python                     %cMauve% %cReset%
echo %cMauve%  %cGrey%[3] Node.js             [4] Cursor                     %cMauve% %cReset%
echo %cMauve%  %cGrey%[5] Git                 [6] GitHub Desktop             %cMauve% %cReset%
echo %cMauve%  %cGreen%Browsers:                                              %cMauve% %cReset%
echo %cMauve%  %cGrey%[7] Arc                 [8] Thorium                    %cMauve% %cReset%
echo %cMauve%  %cGrey%[9] Zen                 [10] Yandex                    %cMauve% %cReset%
echo %cMauve%  %cGreen%Utilities:                                             %cMauve% %cReset%
echo %cMauve%  %cGrey%[11] PowerToys          [12] NanaZip                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[13] Motrix             [14] UniGetUI                  %cMauve% %cReset%
echo %cMauve%  %cGrey%[15] NVCleanstall       [16] NVIDIA Broadcast         %cMauve% %cReset%
echo %cMauve%  %cGreen%Social ^& Productivity:                                 %cMauve% %cReset%
echo %cMauve%  %cGrey%[17] AyuGram            [18] Vesktop                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[19] ChatGPT            [20] Todoist                   %cMauve% %cReset%
echo %cMauve%  %cGrey%[21] Raindrop                                          %cMauve% %cReset%
echo %cMauve%  %cGreen%Gaming:                                                %cMauve% %cReset%
echo %cMauve%  %cGrey%[22] Steam              [23] Epic Games Store          %cMauve% %cReset%
echo %cMauve%  %cGreen%Microsoft Stuff:                                       %cMauve% %cReset%
echo %cMauve%  %cGrey%[24] DirectX            [25] .NET 8.0                  %cMauve% %cReset%
echo %cMauve%  %cGrey%[26] PC Manager         [27] Edge WebView              %cMauve% %cReset%
echo.
echo %cMauve%  %cGrey%[28] Update all installed apps                          %cMauve% %cReset%
echo %cMauve%  %cGrey%[29] Back to Main Menu                                 %cMauve% %cReset%
echo %cMauve% +--------------------------------------------------------+%cReset%

set /p choice="%cSapphire%Enter your choices (space-separated numbers '1 2'): %cReset%"

:: Process each number in the input sequentially
for %%a in (%choice%) do (
    if %%a==0 (
        goto searchPkg
    ) else if %%a==28 (
        echo %cGrey%Updating all installed apps...%cReset%
        winget upgrade --all --accept-package-agreements --accept-source-agreements
        if !errorlevel! equ 0 (
            echo %cGreen%Successfully updated all apps.%cReset%
        ) else (
            echo %cRed%Failed to update some apps. Error code: !errorlevel!%cReset%
            pause
        )
    ) else if %%a==29 (
        goto main
    ) else (
        :: Check if it's a valid number
        set /a "num=%%a" 2>nul
        if !num! geq 1 if !num! leq 27 (
            if defined pkg[%%a] (
                echo.
                echo Installing !pkg[%%a]!...
                winget install --id !pkg[%%a]! --accept-package-agreements --accept-source-agreements
                if !errorlevel! equ 0 (
                    echo Successfully installed !pkg[%%a]!
                ) else if !errorlevel! equ -1978335189 (
                    echo %cGrey%!pkg[%%a]! is already installed. Skipping...%cReset%
                    timeout /t 2
                ) else (
                    echo %cRed%Failed to install !pkg[%%a]!. Error code: !errorlevel!%cReset%
                    echo %cGrey%Opening DuckDuckGo search for alternative download...%cReset%
                    start "" "https://duckduckgo.com/?q=download+!pkg[%%a]!+windows"
                    pause
                )
            ) else (
                echo No package defined for choice %%a
                pause
            )
        ) else (
            echo Invalid choice: %%a%
            pause
        )
    )
)

goto wingetInstall

:searchPkg
cls
echo %cGrey%Enter Program name to search (or 'b' to return):%cReset%
set /p "searchTerm="
if /i "%searchTerm%"=="b" goto wingetInstall
if /i "%searchTerm%"=="" goto searchPkg

echo %cGrey%Searching for "%searchTerm%"...%cReset%
winget search "%searchTerm%"
echo.
echo %cGrey%Enter the exact package ID to install (or 'b' to return):%cReset%
set /p "packageId="
if /i "%packageId%"=="b" goto wingetInstall
if /i "%packageId%"=="" goto searchPkg

call :installPkg "%packageId%"
goto wingetInstall

:installPkg
set "packageId=%~1"
echo.
echo %cGrey%Installing %packageId%...%cReset%
winget install --id %packageId% --accept-package-agreements --accept-source-agreements
if !errorlevel! equ 0 (
    echo %cGreen%Successfully installed %packageId%%cReset%
    goto searchPkg
) else if !errorlevel! equ -1978335189 (
    echo %cGrey%%packageId% is already installed. Skipping...%cReset%
    timeout /t 2
    goto searchPkg
) else (
    echo %cRed%Failed to install %packageId%. Error code: !errorlevel!%cReset%
    echo %cGrey%Opening DuckDuckGo search for alternative download...%cReset%
    start "" "https://duckduckgo.com/?q=download+%packageId%+windows"
    pause
    goto searchPkg
)

exit /b 0