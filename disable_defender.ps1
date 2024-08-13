# Disable Windows Defender features in real time
Set-MpPreference -DisableRealtimeMonitoring $True
Set-MpPreference -ExclusionPath 'C:\'
 
# Persist Windows Defender features settings in registry
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
if (!(Test-Path -Path $path)) {
    New-Item -Path $path -Force
}
New-ItemProperty -Path $path -Name "DisableAntiSpyware" -PropertyType DWord -Value 1 -Force
 
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
if (!(Test-Path -Path $path)) {
    New-Item -Path $path -Force
}
 
New-ItemProperty -Path $path -Name "SubmitSamplesConsent" -PropertyType DWord -Value 2 -Force
 
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
if (!(Test-Path -Path $path)) {
    New-Item -Path $path -Force
}
 
New-ItemProperty -Path $path -Name "DisableRealtimeMonitoring" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $path -Name "DisableBehaviorMonitoring" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $path -Name "DisableOnAccessProtection" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $path -Name "DisableScanOnRealtimeEnable" -PropertyType DWord -Value 1 -Force
 
# Disable windows updates
$key = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
if((Test-Path $key) -ne $TRUE)
{
New-Item -path $key -Force -Verbose
}
New-ItemProperty -Path $key -Name "DisableWindowsUpdateAccess" -Value 1 -propertyType "DWord" -Force -Verbose
New-ItemProperty -Path $key -Name "SetDisableUXWUAccess" -Value 1 -propertyType "DWord" -Force -Verbose
New-ItemProperty -Path $key -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1 -propertyType "DWord" -Force -Verbose
New-ItemProperty -Path $key -Name "DisableOSUpgrade" -Value 1 -propertyType "DWord" -Force -Verbose
 
 
Restart-Computer
