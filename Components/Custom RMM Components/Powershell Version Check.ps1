###
# File: \Powershell Version Check.ps1
# Project: Components
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

<# 
Checks to see what version of powershell a device has. If it is below version 5.1 it throws an error.
If you find devices with an older version of powershell, you can use the Chocolatey component to upgrade to 5.1. Use the Applications argument: "powershell", NewApplications = True, UpdateApplications = False.

The following versions of Windows should not be upgraded:
- Microsoft Exchange Server 2013
- Microsoft Exchange Server 2010 SP3
- Skype for Business Server 2015
- Microsoft Lync Server 2013
- Microsoft Lync Server 2010
- System Center 2012 R2 Service Management Automation 

Post condition suggested:
- Warning text: Alert: Running an old version.  (qualifier: Is found in, resource: StdOut & StdErr)
#>

# Gets a devices powershell version

$VersionInfo = $PSVersionTable.PSVersion
$Version = $VersionInfo.ToString()

if ($VersionInfo.Major -ge 5 -and $VersionInfo.Minor -ge 1) {
    Write-Host "Running a current version. Version: "
    Write-Host $Version
} else {
    Write-Host "Alert: Running and old version. Version: "
    Write-Host $Version
    Write-Error "Alert: Running an old version."
}

if ($Version -and $Version -gt 1) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name Custom2 -Value "$Version" -Force | Out-Null
    Write-Host `r
    Write-Host "Version written to the 'Powershell Version' user defined field."
}