###
# File: \Local Admin Monitoring.ps1
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

################
# Requires 2 variables:
# - LocalAdminsUDF, type string, default value 8 (Which UDF number contains the list of local admins on this device. Numbers 1-30 accepted.)
# - LocalAdminsWhitelistUDF, type string, default value 19 (Which UDF number contains the local admins whitelist for this device. Numbers 1-30 accepted.)
################

$AllowedLocalAdmins = $env:SiteLocalAdmin -split ","
$AllowedLocalAdmins = $AllowedLocalAdmins | ForEach-Object { $_.Trim() }
$LocalAdminsUDF = $env:LocalAdminsUDF # The UDF that contains the list of Local Admins on each device
$LocalAdminsWhitelistUDF = $env:LocalAdminsWhitelistUDF # The UDF that contains a whitelist of local admins that are allowed
$AdminWhitelist = @("Administrator", "Domain Admins", "Enterprise Admins", "Workstation Admins", "Workstation Admins2", "Workstations Admins")

$LocalAdminsWhitelist = [Environment]::GetEnvironmentVariable("UDF_$LocalAdminsWhitelistUDF")
if ($LocalAdminsWhitelist -and $LocalAdminsWhitelist.Trim()) {
	$LocalAdminsWhitelist = $LocalAdminsWhitelist -split ","
	$LocalAdminsWhitelist = $LocalAdminsWhitelist | ForEach-Object { $_.Trim() }
} else {
	$LocalAdminsWhitelist = @()
}

function Get-LocalGroupMembers() {
param ([string]$groupName = $(throw "Need a name") )
	$lines = net localgroup $groupName
	$found = $false
	for ($i = 0; $i -lt $lines.Length; $i++ ) {
		if ( $found ) {
			if ( -not $lines[$i].StartsWith("The command completed")) {
				$lines[$i]
			}
		} elseif ( $lines[$i] -match "^----" ) {
			$found = $true;
		}
	}
}

# Grab from UDF if possible, if not, we'll just get them from the device directly
$LocalAdmins = [Environment]::GetEnvironmentVariable("UDF_$LocalAdminsUDF")

if ($null -eq $LocalAdmins -or !$LocalAdmins) {
	$LocalAdmins = [System.Collections.ArrayList]@()
	foreach ($i in Get-LocalGroupMembers "Administrators") {
		if ($i -and $i -notin $AdminWhitelist -and $i -notlike "TempAdmin-*" -and $i -notlike "*`\TempAdmin-*") {
			if ($i -like "*`\*" -and ($i -split "\\")[1] -in $AdminWhitelist) {
				continue;
			}
			$LocalAdmins.Add($i) | Out-Null
		}
	}
	$LocalAdmins = $LocalAdmins -join ","
}

if ($LocalAdmins) {
	$LocalAdmins = $LocalAdmins -split ","
	$LocalAdminsParsed = [System.Collections.ArrayList]@()
	$LocalAdmins | ForEach-Object { $LocalAdminsParsed.Add($_.Trim()) | Out-Null }

	[System.Collections.ArrayList]$LocalAdminsParsed = $LocalAdmins.Where{ $_ -notmatch "\d\d?\/\d\d?\/\d{4} \d\d?:\d{2}:\d{2} ?(AM|PM)?" -and $_ -notmatch "\d\d\d\d-\d\d-\d\d \d\d?:\d\d:\d\d (AM|PM)" } # Filters out dates from the old local admins script
	$AllowedLocalAdmins | ForEach-Object {
		$AllowedLocalAdmin = $_
		[System.Collections.ArrayList]$LocalAdminsParsed = $LocalAdminsParsed.Where{ $_ -ne $AllowedLocalAdmin }
		[System.Collections.ArrayList]$LocalAdminsParsed = $LocalAdminsParsed.Where{ $_ -notlike "*`\*" -or ($_ -like "*`\*" -and ($_ -split "\\")[1] -ne $AllowedLocalAdmin) }
	}
	$LocalAdminsWhitelist | ForEach-Object {
		$AllowedLocalAdmin = $_
		[System.Collections.ArrayList]$LocalAdminsParsed = $LocalAdminsParsed.Where{ $_ -ne $AllowedLocalAdmin }
		[System.Collections.ArrayList]$LocalAdminsParsed = $LocalAdminsParsed.Where{ $_ -notlike "*`\*" -or ($_ -like "*`\*" -and ($_ -split "\\")[1] -ne $AllowedLocalAdmin) }
	}

	$LocalAdminsParsedStr = $LocalAdminsParsed -join ", "

	if ($LocalAdminsParsed.Count -gt 0) {
		Write-Warning "Device has unacceptable local admins. :("
		Write-Host "<-Start Result->"
		Write-Host "Local Admins=BAD (${LocalAdminsParsedStr})"
		Write-Host "Local Admin Accounts: "
		Write-Host "<-End Result->"
		exit 1
	}
}

Write-Host "Device has NO unacceptable local admins. :)"
Write-Host "<-Start Result->"
Write-Host "Local Admins=GOOD"
Write-Host "<-End Result->"
exit 0