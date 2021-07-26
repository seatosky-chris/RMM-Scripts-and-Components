# Enables local backups in OneDrive.
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
$TenantID = $env:TenantID

if (!(Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

New-ItemProperty -Path $regPath -Name FilesOnDemandEnabled -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $regPath -Name ForcedLocalMassDeleteDetection -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $regPath -Name SilentAccountConfig -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $regPath -Name KFMSilentOptInWithNotification -Value 1 -PropertyType DWORD -Force | Out-Null

New-ItemProperty -Path $regPath -Name KFMSilentOptIn -Value $TenantID -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name KFMOptInWithWizard -Value $TenantID -PropertyType String -Force | Out-Null

New-ItemProperty -Path $regPath -Name LocalMassDeleteFileDeleteThreshold -Value 20 -PropertyType DWORD -Force | Out-Null