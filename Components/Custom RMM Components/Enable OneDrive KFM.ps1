###
# File: \Enable OneDrive KFM.ps1
# Project: Custom RMM Components
# Created Date: Tuesday, August 2nd 2022, 10:37:14 am
# Author: Chris Jantzen
# -----
# Last Modified: Mon Mar 06 2023
# Modified By: Chris Jantzen
# -----
# Copyright (c) 2023 Sea to Sky Network Solutions
# License: MIT License
# -----
# 
# HISTORY:
# Date      	By	Comments
# ----------	---	----------------------------------------------------------
###

###########
# Requires a variable TenantID, type String, that is set to the O365 Tenant ID of the customer
###########

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