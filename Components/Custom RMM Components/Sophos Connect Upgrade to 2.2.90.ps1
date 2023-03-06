###
# File: \Sophos Connect Upgrade to 2.2.90.ps1
# Project: RMM Components
# Created Date: Monday, March 3rd 2023, 10:36:58 am
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

######################
# Download the Sophos Connect client from https://www.sophos.com/en-us/support/downloads/utm-downloads and attach the file
# if the version has changed, you will need to update the file name in the script below

$LogLocation = "C:\STS" # Replace with your preferred log location
######################
 
# Thanks to Giga on MSPGeek's Discord for this code that kills any open Sophos VPN connections
$connections = (&"C:\Program Files (x86)\Sophos\Connect\sccli" list).Replace("Connections:","").Replace("  ","").Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)

foreach ($connection in $connections)
{
    &"C:\Program Files (x86)\Sophos\Connect\sccli" disable -n $connection
}

$InstallLocation = $false
if (Test-Path -Path "C:\Program Files (x86)\Sophos\Connect\") {
    $InstallLocation = "C:\Program Files `(x86`)\Sophos\Connect"
} elseif (Test-Path -Path "C:\Program Files\Sophos\Connect\") {
    $InstallLocation = "C:\Program Files\Sophos\Connect"
}

New-Item -ItemType Directory -Force -Path $LogLocation

$DataStamp = get-date -Format yyyyMMddTHHmmss
$logFile = '{0}\{1}-{2}.log' -f $LogLocation, "$(hostname)-sophosconnect_install", $DataStamp

if ($InstallLocation) {
    Write-Host "Installing to: $InstallLocation"
    msiexec /i SophosConnect_2.2.90_IPsec_and_SSLVPN.msi INSTALLFOLDER=`"$InstallLocation`" /qn /norestart /L*v `"$logFile`"
} else {
    Write-Host "Installing to default location"
    msiexec /a SophosConnect_2.2.90_IPsec_and_SSLVPN.msi /qn /norestart /L*v `"$logFile`"
}