###
# File: \ScreenConnect Monitoring Component.ps1
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

###########
# 3 variables are required:
# - scID, type string, default value is your SC instance ID (Your ScreenConnect Instance ID. You can find it via the registry editor of a computer with SC on it. Navigate to: Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ScreenConnect Client (xxxxxxxx). Get the ID in the brackets of the key name.)
# - scHostURL, type string, default value is your All Machines url (Get this URL from your address bar after clicking the "Access" button on the left sidebar in SC and then navigating to a folder with all devices in it.)
# - UDF, type string (Which UDF number to place the link into. Numbers 1-30 accepted.)
###########

$SCHostID = $env:scID #ScreenConnect Instance ID
$SCHostURL = $env:scHostURL.split('/')[2]+"/"+$env:scHostURL.split('/')[3]+"/"+$env:scHostURL.split('/')[4]
$CustomVariable = $env:UDF

if (Get-Service | Where-Object {($_.name -ilike "*$SCHostID*") -and ($_.Status -eq "Running")}) { # If case-insensitive result returned, added filter pull running service only
	$key = "HKLM:\SYSTEM\CurrentControlSet\Services\ScreenConnect Client ($SCHostID)"
	$screenconnectData = (Get-ItemProperty -Path $key -Name ImagePath).ImagePath

	$scGuidRegex = '&s=((\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1})&[a-z]='
	$sessionID = $null
	if ($screenconnectData -match $scGuidRegex) {
		$sessionID = $matches[1]
	}

	if ($sessionID.Length -eq "36") {
		#$JoinURL
		Write-Output "Setting SC session ID to $sessionID"
		$JoinURL = "https://$SCHostURL//$sessionID/Join"
		$JoinURL=$JoinURL.Replace(' ','%20') # fix for new UI

		$key = "Custom" + $CustomVariable
		New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name $key -PropertyType String -Value $JoinURL -Force
		write-host '<-Start Result->ScreenConnect=Running<-End Result->'
		exit 0
	} #end if session ID value is valid
} else { #no service running
	write-host '<-Start Result->ScreenConnect=Not running<-End Result->'
	exit 1
}