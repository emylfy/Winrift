. "$PSScriptRoot\..\..\scripts\Common.ps1"

function Invoke-PrivacyHardening {
    $ErrorActionPreference = 'SilentlyContinue'

    Write-Host "  Applying registry tweaks..."
    $registryTweaks = @(
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\SideBySide\Configuration"; Name = "DisableResetbase"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Name = "HasAccepted"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"; Name = "NumberOfSIUFInPeriod"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"; Name = "RestrictImplicitTextCollection"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"; Name = "PreventHandwritingErrorReports"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC"; Name = "PreventHandwritingDataSharing"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization"; Name = "AllowInputPersonalization"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"; Name = "HarvestContacts"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableSensors"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"; Name = "value"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"; Name = "AutoConnectAllowedOEM"; Value = 0 }
        @{ Path = "HKCU:\Control Panel\International\User Profile"; Name = "HttpAcceptLanguageOptOut"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps"; Name = "AllowUntriggeredNetworkTrafficOnSettingsPage"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps"; Name = "AutoDownloadAndUpdateMapData"; Value = 0 }
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name = "AllowGameDVR"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\WMDRM"; Name = "DisableOnline"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Input\TIPC"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Input\TIPC"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoDriveTypeAutoRun"; Value = 255 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoAutorun"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "NoAutoplayfornonVolume"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"; Name = "NoLockScreenCamera"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name = "NoLMHash"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"; Name = "AlwaysInstallElevated"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"; Name = "DisableExceptionChainValidation"; Value = 0 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\WCN\UI"; Name = "DisableWcnUi"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars"; Name = "DisableFlashConfigRegistrar"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars"; Name = "DisableInBand802DOT11Registrar"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars"; Name = "DisableUPnPRegistrar"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars"; Name = "DisableWPDRegistrar"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars"; Name = "EnableRegistrars"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "DisableLockScreenAppNotifications"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"; Name = "NoTileApplicationNotification"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "NoUseStoreOpenWith"; Value = 1 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI"; Name = "DisableMFUTracking"; Value = 1 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI"; Name = "DisableRecentApps"; Value = 1 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI"; Name = "TurnOffBackstack"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessLocation"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessLocation_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessLocation_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessLocation_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"; Name = "Status"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessAccountInfo"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessAccountInfo_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessAccountInfo_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessAccountInfo_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMotion"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMotion_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMotion_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMotion_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\activity"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTrustedDevices"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTrustedDevices_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTrustedDevices_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTrustedDevices_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsSyncWithDevices"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsSyncWithDevices_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsSyncWithDevices_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsSyncWithDevices_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsGetDiagnosticInfo"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsGetDiagnosticInfo_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsGetDiagnosticInfo_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsGetDiagnosticInfo_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessContacts"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessContacts_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessContacts_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessContacts_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCalendar"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCalendar_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCalendar_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCalendar_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessEmail"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessEmail_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessEmail_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessEmail_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTasks"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTasks_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTasks_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessTasks_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E390DF20-07DF-446D-B962-F5C953062741}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessRadios"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessRadios_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessRadios_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessRadios_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessBackgroundSpatialPerception"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessBackgroundSpatialPerception_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessBackgroundSpatialPerception_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessBackgroundSpatialPerception_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\spatialPerception"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\backgroundSpatialPerception"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGazeInput"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGazeInput_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGazeInput_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGazeInput_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessHumanPresence"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessHumanPresence_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessHumanPresence_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessHumanPresence_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\humanPresence"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureProgrammatic"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureProgrammatic_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureProgrammatic_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureProgrammatic_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\graphicsCaptureProgrammatic"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureWithoutBorder"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureWithoutBorder_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureWithoutBorder_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessGraphicsCaptureWithoutBorder_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\graphicsCaptureWithoutBorder"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\humanInterfaceDevice"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\Software\Policies\Microsoft\SQMClient\Windows"; Name = "CEIPEnable"; Value = 0 }
        @{ Path = "HKLM:\Software\Microsoft\SQMClient\Windows"; Name = "CEIPEnable"; Value = 0 }
        @{ Path = "HKLM:\Software\Microsoft\SQMClient"; Name = "UploadDisableFlag"; Value = 0 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\AppCompat"; Name = "AITEnable"; Value = 0 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\AppCompat"; Name = "DisableEngine"; Value = 1 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\AppCompat"; Name = "DisableUAR"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "DisableInventory"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform"; Name = "NoGenTicket"; Value = 1 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1 }
        @{ Path = "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent"; Name = "DefaultConsent"; Value = 1 }
        @{ Path = "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent"; Name = "DefaultOverrideBehavior"; Value = 1 }
        @{ Path = "HKLM:\Software\Microsoft\Windows\Windows Error Reporting"; Name = "DontSendAdditionalData"; Value = 1 }
        @{ Path = "HKLM:\Software\Microsoft\Windows\Windows Error Reporting"; Name = "LoggingDisabled"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"; Name = "DODownloadMode"; Value = 0 }
        @{ Path = "HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings"; Name = "DownloadMode"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization"; Name = "SystemSettingsDownloadMode"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocationScripting"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name = "SensorPermissionState"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowSearchToUseLocation"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "AllowSearchToUseLocation"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchPrivacy"; Value = 3 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "IsMSACloudSearchEnabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "IsAADCloudSearchEnabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds"; Name = "EnableExperimentation"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds"; Name = "EnableConfigFlighting"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation"; Name = "value"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds"; Name = "AllowBuildPreview"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableSyncOnPaidNetwork"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "SyncPolicy"; Value = 5 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableApplicationSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableApplicationSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableAppSyncSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableAppSyncSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableCredentialsSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableCredentialsSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableDesktopThemeSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableDesktopThemeSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisablePersonalizationSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisablePersonalizationSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableStartLayoutSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableStartLayoutSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableWebBrowserSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableWebBrowserSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableWindowsSettingSync"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableWindowsSettingSyncUserOverride"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\musicLibrary"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCallHistory"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCallHistory_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCallHistory_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessCallHistory_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMessaging"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMessaging_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMessaging_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsAccessMessaging_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{21157C1F-2651-4CC1-90CA-1F28B02263F6}"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync"; Name = "Value"; Value = "Deny"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoice"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoice_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoice_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoice_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"; Name = "AgentActivationEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoiceAboveLock"; Value = 2 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoiceAboveLock_UserInControlOfTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoiceAboveLock_ForceAllowTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsActivateWithVoiceAboveLock_ForceDenyTheseApps"; Value = "\0"; Type = "MultiString" }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"; Name = "AgentActivationOnLockScreenEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe"; Name = "Debugger"; Value = "%SYSTEMROOT%\System32\taskkill.exe"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "DisablePCA"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe"; Name = "Debugger"; Value = "%SYSTEMROOT%\System32\taskkill.exe"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowCommercialDataPipeline"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowUpdateComplianceProcessing"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana"; Name = "value"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCloudSearch"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortanaAboveLock"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CanCortanaBeEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaEnabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaEnabled"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCortanaButton"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaInAmbientMode"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowIndexingEncryptedStoresOrItems"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AlwaysUseAutoLangDetection"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "PreventRemoteQueries"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "PreventUnwantedAddIns"; Value = ""; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "DisableSearchBoxSuggestions"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "DisableSearchBoxSuggestions"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWeb"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWebOverMeteredConnections"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "EnableDynamicContentInWSB"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; Name = "IsDynamicSearchBoxEnabled"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "HistoryViewEnabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "DeviceHistoryEnabled"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Preferences"; Name = "VoiceActivationOn"; Value = 0 }
        @{ Path = "HKLM:\Software\Microsoft\Speech_OneCore\Preferences"; Name = "VoiceActivationDefaultOn"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "VoiceShortcut"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Preferences"; Name = "VoiceActivationEnableAboveLockscreen"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Preferences"; Name = "ModelDownloadAllowed"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"; Name = "DisableVoice"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableSoftLanding"; Value = 1 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1 }
        @{ Path = "HKLM:\Software\Policies\Microsoft\VisualStudio\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\VSCommon\14.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\VSCommon\15.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\VSCommon\16.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM"; Name = "OptIn"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\VisualStudio\Telemetry"; Name = "TurnOffSwitch"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback"; Name = "DisableFeedbackDialog"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback"; Name = "DisableEmailInput"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback"; Name = "DisableScreenshotCapture"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode"; Name = "DisableRemoteAnalysis"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode"; Name = "DisableRemoteAnalysis"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode"; Name = "DisableRemoteAnalysis"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client"; Name = "OptInOrOutPreference"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"; Name = "EnableRID44231"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"; Name = "EnableRID64640"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS"; Name = "EnableRID66610"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup"; Name = "SendTelemetryData"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar"; Name = "EnableCalendarLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar"; Name = "EnableCalendarLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Word\Options"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\OSM"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\OSM"; Name = "EnableLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Office\15.0\OSM"; Name = "EnableUpload"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\OSM"; Name = "EnableUpload"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry"; Name = "DisableTelemetry"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry"; Name = "DisableTelemetry"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry"; Name = "DisableTelemetry"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry"; Name = "VerboseLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry"; Name = "VerboseLogging"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry"; Name = "VerboseLogging"; Value = 0 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Office\15.0\Common"; Name = "QMEnable"; Value = 0 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Office\16.0\Common"; Name = "QMEnable"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Common\Feedback"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Feedback"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences"; Name = "UsageTracking"; Value = 0 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer"; Name = "PreventCDDVDMetadataRetrieval"; Value = 1 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer"; Name = "PreventMusicFileMetadataRetrieval"; Value = 1 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer"; Name = "PreventRadioPresetsRetrieval"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\WMDRM"; Name = "DisableOnline"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeFollowEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "RelatedMatchesCloudServiceEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SignInCtaOnNtpEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeEnhanceImagesEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AlternateErrorPagesEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AutofillCreditCardEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ExperimentationAndConfigurationServiceControl"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "StartupBoostEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ResolveNavigationErrorsUseWebService"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"; Name = "PreventLiveTileDataCollection"; Value = 1 }
        @{ Path = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main"; Name = "PreventLiveTileDataCollection"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\SearchScopes"; Name = "ShowSearchSuggestionsGlobal"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\SearchScopes"; Name = "ShowSearchSuggestionsGlobal"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\BooksLibrary"; Name = "EnableExtendedBooksTelemetry"; Value = 0 }
        @{ Path = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\BooksLibrary"; Name = "EnableExtendedBooksTelemetry"; Value = 0 }
        @{ Path = "HKCU:\Software\Policies\Microsoft\Internet Explorer\Geolocation"; Name = "PolicyDisableGeolocation"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Safety\PrivacIE"; Name = "DisableLogging"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM"; Name = "DisableCustomerImprovementProgram"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"; Name = "CallLegacyWCMPolicies"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"; Name = "EnableSSL3Fallback"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"; Name = "PreventIgnoreCertErrors"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\software_reporter_tool.exe"; Name = "Debugger"; Value = "%SYSTEMROOT%\System32\taskkill.exe"; Type = "String" }
        @{ Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"; Name = "MetricsReportingEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"; Name = "DisableDefaultBrowserAgent"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"; Name = "DisableTelemetry"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "DiagnosticData"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "MetricsReportingEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SendSiteInfoToImproveServices"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "UserFeedbackAllowed"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SpotlightExperiencesAndRecommendationsEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ShowRecommendationsEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "BingAdsSuppression"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "PromotionalTabsEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "PersonalizationReportingEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "MicrosoftEdgeInsiderPromotionEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ShowAcrobatSubscriptionButton"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageHideDefaultTopSites"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ConfigureDoNotTrack"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"; Name = "DoNotUpdateToEdgeWithChromium"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "InstallDefault"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "Install{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "Install{65C35B14-6C1D-4122-AC46-7148CC9D6497}"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "Install{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"; Name = "ChromeCleanupReportingEnabled"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"; Name = "ChromeCleanupEnabled"; Value = 0 }
        @{ Path = "HKCU:\Software\Microsoft\Clipboard"; Name = "EnableClipboardHistory"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowClipboardHistory"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman"; Name = "ServerMinKeyBitLength"; Value = 2048 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman"; Name = "ClientMinKeyBitLength"; Value = 2048 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client"; Name = "AllowBasic"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name = "restrictanonymoussam"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"; Name = "restrictnullsessaccess"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\LSA"; Name = "restrictanonymous"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"; Name = "fAllowToGetHelp"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"; Name = "fAllowFullControl"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"; Name = "AllowBasic"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"; Name = "SMBv1"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"; Name = "DisabledByDefault"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"; Name = "DisabledByDefault"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"; Name = "DisabledByDefault"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"; Name = "Enabled"; Value = 0 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"; Name = "DisabledByDefault"; Value = 1 }
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name = "LmCompatibilityLevel"; Value = 5 }
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowOnlineTips"; Value = 0 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoInternetOpenWith"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoOnlinePrintsWizard"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoPublishingWizard"; Value = 1 }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "NoWebServices"; Value = 1 }
    )
    foreach ($r in $registryTweaks) {
        $p = $r.Path
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name $r.Name -Value $r.Value -Type ($r.Type ?? "DWord") -Force
    }

    Write-Host "  Removing registry values..."
    @(
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"; Name = "PeriodInNanoSeconds" }
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit"; Name = "LastKey" }
        @{ Path = "HKLM:\Software\Microsoft\VisualStudio\DiagnosticsHub"; Name = "LogLevel" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Name = "OneDriveSetup" }
    ) | ForEach-Object { Remove-ItemProperty -Path $_.Path -Name $_.Name -Force }

    Write-Host "  Disabling services..."
    @(
        "Razer Game Scanner Service", "LogiRegistryService", "wersvc", "wercplsupport",
        "wisvc", "PcaSvc", "DiagTrack", "dmwappushservice", "VSStandardCollectorService150",
        "gupdate", "gupdatem", "AdobeARMservice", "adobeupdateservice",
        "dbupdate", "dbupdatem", "WMPNetworkSvc", "edgeupdate", "edgeupdatem",
        "mrxsmb10", "XblGameSave", "XboxNetApiSvc", "XblAuthManager", "MapsBroker", "RetailDemo"
    ) | ForEach-Object {
        $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
        if (-not $svc) { return }
        if ($svc.Status -eq 'Running') { Stop-Service -Name $_ -Force }
        Set-Service -Name $_ -StartupType Disabled
    }

    Write-Host "  Disabling scheduled tasks..."
    @(
        "\Microsoft\Windows\ErrorDetails\EnableErrorDetailsUpdate",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
        "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\Uploader",
        "\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerCeipAssistant",
        "\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleCollector",
        "\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleUsageCollector",
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Application Experience\AitAgent",
        "\Microsoft\Windows\Device Information\Device",
        "\Microsoft\Windows\Device Information\Device User",
        "\Microsoft\Office\OfficeTelemetryAgentFallBack",
        "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
        "\Microsoft\Office\OfficeTelemetryAgentLogOn",
        "\Microsoft\Office\OfficeTelemetryAgentLogOn2016",
        "Adobe Acrobat Update Task",
        "DropboxUpdateTaskMachineUA",
        "DropboxUpdateTaskMachineCore",
        "NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
        "NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
        "\Mozilla\Firefox Default Browser Agent 308046B0AF4A39CB",
        "\Mozilla\Firefox Default Browser Agent D2CEEC440E2074BD"
    ) | ForEach-Object { Disable-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue }

    Write-Host "  Removing bloatware apps..."
    @(
        "Microsoft.549981C3F5F10", "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "Microsoft.NetworkSpeedTest", "Microsoft.XboxApp", "Microsoft.Xbox.TCUI",
        "Microsoft.XboxSpeechToTextOverlay", "Microsoft.Print3D", "Windows.Print3D",
        "Microsoft.BingWeather", "Microsoft.BingSports", "Microsoft.BingNews",
        "Microsoft.BingFinance", "Microsoft.MicrosoftOfficeHub", "Microsoft.WindowsPhone",
        "Microsoft.CommsPhone", "Microsoft.Windows.Holographic.FirstRun",
        "Microsoft.Windows.ParentalControls", "Microsoft.WindowsFeedback", "Windows.CBSPreview"
    ) | ForEach-Object {
        Get-AppxPackage -Name $_ -AllUsers | Remove-AppxPackage -AllUsers
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$_*" } | Remove-AppxProvisionedPackage -Online
        $deprovKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\${_}_cw5n1h2txyewy"
        if (-not (Test-Path $deprovKey)) { New-Item -Path $deprovKey -Force | Out-Null }
    }

    Write-Host "  Disabling Windows features..."
    @(
        "MicrosoftWindowsPowerShellV2", "MicrosoftWindowsPowerShellV2Root",
        "TelnetClient", "TFTP", "SMB1Protocol", "SMB1Protocol-Client",
        "SMB1Protocol-Server", "ScanManagementConsole", "FaxServicesClientPackage",
        "Xps-Foundation-Xps-Viewer"
    ) | ForEach-Object { Disable-WindowsOptionalFeature -Online -FeatureName $_ -NoRestart | Out-Null }

    Write-Host "  Setting environment variables..."
    [System.Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT", "1", "Machine")
    [System.Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", "Machine")

    Write-Host "  Blocking telemetry domains..."
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $domains = @(
        "oca.telemetry.microsoft.com", "oca.microsoft.com",
        "kmwatsonc.events.data.microsoft.com", "watson.telemetry.microsoft.com",
        "umwatsonc.events.data.microsoft.com", "ceuswatcab01.blob.core.windows.net",
        "ceuswatcab02.blob.core.windows.net", "eaus2watcab01.blob.core.windows.net",
        "eaus2watcab02.blob.core.windows.net", "weus2watcab01.blob.core.windows.net",
        "weus2watcab02.blob.core.windows.net", "co4.telecommand.telemetry.microsoft.com",
        "cs11.wpc.v0cdn.net", "cs1137.wpc.gammacdn.net", "modern.watson.data.microsoft.com",
        "functional.events.data.microsoft.com", "browser.events.data.msn.com",
        "self.events.data.microsoft.com", "v10.events.data.microsoft.com",
        "v10c.events.data.microsoft.com", "us-v10c.events.data.microsoft.com",
        "eu-v10c.events.data.microsoft.com", "v10.vortex-win.data.microsoft.com",
        "vortex-win.data.microsoft.com", "telecommand.telemetry.microsoft.com",
        "www.telecommandsvc.microsoft.com", "umwatson.events.data.microsoft.com",
        "watsonc.events.data.microsoft.com", "eu-watsonc.events.data.microsoft.com",
        "config.edge.skype.com", "telemetry.dropbox.com", "telemetry.v.dropbox.com"
    )
    $hostsContent = Get-Content $hostsFile -Raw
    $newEntries = @()
    foreach ($d in $domains) {
        if ($hostsContent -notmatch [regex]::Escape($d)) {
            $newEntries += "0.0.0.0 $d"
        }
    }
    if ($newEntries.Count -gt 0) {
        Add-Content -Path $hostsFile -Value ($newEntries -join "`n")
    }

    Write-Host "  Blocking telemetry executables..."
    @("CompatTelRunner", "DeviceCensus", "software_reporter_tool") | ForEach-Object {
        Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
    }
    $disallowRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun"
    if (-not (Test-Path $disallowRunPath)) { New-Item -Path $disallowRunPath -Force | Out-Null }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisallowRun" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $disallowRunPath -Name "1" -Value "CompatTelRunner.exe" -Type String -Force
    Set-ItemProperty -Path $disallowRunPath -Name "2" -Value "DeviceCensus.exe" -Type String -Force
    Set-ItemProperty -Path $disallowRunPath -Name "3" -Value "software_reporter_tool.exe" -Type String -Force

    Write-Host "  Removing NVIDIA telemetry..."
    $nvDir = "$env:ProgramFiles\NVIDIA Corporation\Installer2"
    if (Test-Path $nvDir) {
        & rundll32.exe "$nvDir\NVI2.DLL,UninstallPackage NvTelemetryContainer" 2>$null
        & rundll32.exe "$nvDir\NVI2.DLL,UninstallPackage NvTelemetry" 2>$null
    }

    Write-Host "  Disabling VS Code telemetry..."
    $vsCodeSettings = "$env:APPDATA\Code\User\settings.json"
    if (Test-Path $vsCodeSettings) {
        $json = Get-Content $vsCodeSettings -Raw | ConvertFrom-Json
        $json | Add-Member -NotePropertyName "telemetry.enableTelemetry" -NotePropertyValue $false -Force
        $json | Add-Member -NotePropertyName "telemetry.enableCrashReporter" -NotePropertyValue $false -Force
        $json | Add-Member -NotePropertyName "workbench.enableExperiments" -NotePropertyValue $false -Force
        $json | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettings -Encoding UTF8
    }

    Write-Host "  Applying miscellaneous hardening..."
    & net user defaultuser0 /delete 2>$null
    & dism.exe /online /Remove-DefaultAppAssociations 2>$null
    & sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi 2>$null
    $key = 'HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces'
    Get-ChildItem $key | ForEach-Object { Set-ItemProperty -Path "$key\$($_.PSChildName)" -Name NetbiosOptions -Value 2 }

    foreach ($role in @("Client", "Server")) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.2\$role" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.2\$role" -Name "Enabled" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.2\$role" -Name "DisabledByDefault" -Value 0 -Type DWord -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\$role" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\$role" -Name "Enabled" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\$role" -Name "DisabledByDefault" -Value 0 -Type DWord -Force
    }

    Write-Host "  Clearing history and MRU data..."
    @(
        "HKCU:\Software\Adobe\MediaBrowser\MRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\RecentApps",
        "HKCU:\Software\Microsoft\Internet Explorer\TypedURLs",
        "HKCU:\Software\Microsoft\Internet Explorer\TypedURLsTime",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\CIDSizeMRU",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\FirstFolder",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRULegacy",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Get-Item $_ | Select-Object -ExpandProperty Property | ForEach-Object { Remove-ItemProperty -Path $using:_ -Name $_ -Force }
        }
    }

    Write-Host "  Cleaning telemetry files..."
    @(
        "%LOCALAPPDATA%\Microsoft\Windows\ConnectedSearch\History",
        "%APPDATA%\Microsoft\Windows\Recent Items",
        "%APPDATA%\Macromedia\Flash Player",
        "%USERPROFILE%\.dotnet\TelemetryStorageService",
        "%SYSTEMROOT%\Temp",
        "%TEMP%",
        "%SYSTEMROOT%\Prefetch",
        "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations",
        "%PROGRAMFILES(X86)%\Steam\Dumps",
        "%PROGRAMFILES(X86)%\Steam\Traces",
        "%ProgramFiles(x86)%\Steam\appcache",
        "%LOCALAPPDATA%\Microsoft\VSCommon\14.0\SQM",
        "%LOCALAPPDATA%\Microsoft\VSCommon\15.0\SQM",
        "%LOCALAPPDATA%\Microsoft\VSCommon\16.0\SQM",
        "%LOCALAPPDATA%\Microsoft\VSCommon\17.0\SQM",
        "%LOCALAPPDATA%\Microsoft\VSApplicationInsights",
        "%PROGRAMDATA%\Microsoft\VSApplicationInsights",
        "%TEMP%\Microsoft\VSApplicationInsights",
        "%APPDATA%\vstelemetry",
        "%PROGRAMDATA%\vstelemetry",
        "%TEMP%\VSFaultInfo",
        "%TEMP%\VSFeedbackPerfWatsonData",
        "%TEMP%\VSFeedbackVSRTCLogs",
        "%TEMP%\VSFeedbackIntelliCodeLogs",
        "%TEMP%\VSRemoteControl",
        "%TEMP%\Microsoft\VSFeedbackCollector",
        "%TEMP%\VSTelem",
        "%TEMP%\VSTelem.Out",
        "%LOCALAPPDATA%\Microsoft\Windows\INetCache\IE",
        "%LOCALAPPDATA%\Microsoft\Windows\WebCache",
        "%USERPROFILE%\Local Settings\Temporary Internet Files",
        "%LOCALAPPDATA%\Microsoft\Windows\Temporary Internet Files",
        "%LOCALAPPDATA%\Microsoft\Windows\INetCache",
        "%LOCALAPPDATA%\Temporary Internet Files",
        "%LOCALAPPDATA%\Microsoft\Feeds Cache",
        "%LOCALAPPDATA%\Microsoft\InternetExplorer\DOMStore",
        "%LOCALAPPDATA%\Google\Chrome\User Data\Crashpad\reports",
        "%LOCALAPPDATA%\Google\CrashReports",
        "%SYSTEMROOT%\Panther",
        "%SYSTEMROOT%\ServiceProfiles\LocalService\AppData\Local\Temp",
        "%LOCALAPPDATA%\Microsoft\CLR_v4.0\UsageTraces",
        "%LOCALAPPDATA%\Microsoft\CLR_v4.0_32\UsageTraces",
        "%SYSTEMROOT%\Logs\NetSetup",
        "%SYSTEMROOT%\Temp\CBS",
        "%SYSTEMROOT%\Logs\waasmedic",
        "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl",
        "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\AutoLogger-Diagtrack-Listener.etl",
        "%LOCALAPPDATA%\Google\Software Reporter Tool\*.log",
        "%USERPROFILE%\Local Settings\Application Data\Safari\WebpageIcons.db",
        "%LOCALAPPDATA%\Apple Computer\Safari\WebpageIcons.db",
        "%USERPROFILE%\Local Settings\Application Data\Apple Computer\Safari\Cache.db",
        "%LOCALAPPDATA%\Apple Computer\Safari\Cache.db",
        "%SYSTEMROOT%\comsetup.log",
        "%SYSTEMROOT%\DtcInstall.log",
        "%SYSTEMROOT%\setupact.log",
        "%SYSTEMROOT%\setuperr.log",
        "%SYSTEMROOT%\setupapi.log",
        "%SYSTEMROOT%\inf\setupapi.app.log",
        "%SYSTEMROOT%\inf\setupapi.dev.log",
        "%SYSTEMROOT%\inf\setupapi.offline.log",
        "%SYSTEMROOT%\Performance\WinSAT\winsat.log",
        "%SYSTEMROOT%\debug\PASSWD.LOG",
        "%SYSTEMROOT%\Logs\CBS\CBS.log",
        "%SYSTEMROOT%\Logs\DISM\DISM.log",
        "%SYSTEMROOT%\System32\catroot2\dberr.txt",
        "%SYSTEMROOT%\System32\catroot2.log",
        "%SYSTEMROOT%\System32\catroot2.jrs",
        "%SYSTEMROOT%\System32\catroot2.edb",
        "%SYSTEMROOT%\System32\catroot2.chk"
    ) | ForEach-Object {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($_)
        Remove-Item -Path $expanded -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Show-PrivacyMenu {
    Initialize-Logging -ModuleName "privacy"
    $Host.UI.RawUI.WindowTitle = "Privacy Hardening"
    $confirm = Show-InteractiveMenu -Title "Privacy Hardening" -HideKeys -Items @(
        "Applies ~200 privacy and security settings.",
        "Disables telemetry, tracking, bloatware, AI features.",
        "Based on privacy.sexy standard preset.",
        "---",
        "Y › Run privacy hardening",
        "N › Cancel"
    )
    if ($confirm -ne "Y") { return }

    Clear-Host
    Invoke-PrivacyHardening
    Write-Host ""
    Write-Log -Message "Privacy hardening completed." -Level SUCCESS
    Wait-ForUser
}

if ($MyInvocation.InvocationName -ne '.') { Show-PrivacyMenu }
