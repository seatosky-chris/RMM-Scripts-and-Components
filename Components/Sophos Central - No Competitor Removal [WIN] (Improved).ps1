<# 
Installs Sophos Endpoint with the new Thin installer using client's defaults.

Doesn't attempt to remove Competitive Products

Relies on site variables being properly populated:

* SophosCustToken 
* SophosMgmtServer 
* SophosProducts

Setup Instructions found here:

https://community.sophos.com/msp-flex-integrations/

Note: This version has been improved to not break when the SSL version is old. It is otherwise the exact same as the original, but is less likely to break. 
#>

# -----------------------------------------------------------------------------------------------
# Component: Sophos Central Installer
# Author: Stephen Weber
# Purpose: Using the new Sophos Thin installer, 
#          perform default install of Sophos Central using the Predefined Variables in each Site.
# Version 1.2
# -----------------------------------------------------------------------------------------------

# Define Functions

function Get-SophosInstalled {

	$Global:installed = (gp HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sophos Endpoint Agent"
	$Global:mcsclient = Get-Service -name "Sophos MCS Client" -ea SilentlyContinue
	$Global:mcsagent = Get-Service -name "Sophos MCS Agent" -ea SilentlyContinue
}
	
# Fix SSL protocol if necessary (without this web requests may break)
$CurrentTLS = [System.Net.ServicePointManager]::SecurityProtocol
if ($CurrentTLS -notlike "*Tls12" -and $CurrentTLS -notlike "*Tls13") {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	Write-Host "This device is using an old version of TLS. Temporarily changed to use TLS v1.2."
}

# Sophos Central Installation

Write-Host "Starting the Sophos Central Installation based on the variables defined in the site"
Write-Host ""
Write-Host "Checking to see if Sophos is Already Installed"

Get-SophosInstalled
if ($installed -eq "True") {
	Write-Host "--Sophos Central Endpoint Agent Installed"
	if ($mcsclient.Status -eq "Running"){	
	Write-Host "--Sophos MCS Client is Running"
	Exit 0
	}
} else {
	Write-Host "--Sophos Central is Not Installed"
	Write-Host "Sophos MCS Client is Not Running"
}

# Check for the Site Variables
Write-Host ""
Write-Host "Checking the Variables"

if ($ENV:SophosCustToken -eq $null)
	{Write-Host "--Customer Token Not Set or Missing"
	Exit 1}
else
	{Write-Host "--CustomerToken = "$ENV:SophosCustToken""}

if ($ENV:SophosProducts -eq $null)
	{Write-Host "--Sophos Products Not Set or Missing"
	Exit 1}
else
	{Write-Host "--Products = "$ENV:SophosProducts""}

# Sophos parameters are defined from the site specific variables
$arguments = "--products=""" + $ENV:SophosProducts
$arguments = $arguments + """ --nocompetitorremoval"""
$arguments = $arguments + """ --quiet"

# Check to see if a previous SophosSetup Process is running
Write-Host ""
Write-Host "Checking to see if SophosSetup.exe is already running"
if ((get-process "sophossetup" -ea SilentlyContinue) -eq $Null){
		Write-Host "--SophosSetup Not Running" 
}
else {
	Write-Host "Sophos Currently Running, Will Kill the Process before Continuing"
	Stop-Process -processname "sophossetup"
	}

# Download of the Central Customer Installer
Write-Host ""
Write-Host "Downloading Sophos Central Installer"
Invoke-WebRequest -Uri "https://central.sophos.com/api/partners/download/windows/v1/$ENV:SophosCustToken/SophosSetup.exe" -OutFile SophosSetup.exe
if ((Test-Path SophosSetup.exe) -eq "True"){
		Write-Host "--Sophos Setup Installer Downloaded Successfully"
}
else {
	Write-Host "--Sophos Central Installer Did Not Download - Please check Firewall or Web Filter"
	Exit 1
}

# This Section starts the installer using the arguments defined above
Write-Host ""
Write-Host "Installing Sophos Central Endpoint:"
Write-Host ""
Write-Host "SophosSetup.exe "$arguments""
Write-Host ""

start-process SophosSetup.exe $arguments

$timeout = new-timespan -Minutes 30
$install = [diagnostics.stopwatch]::StartNew()
while ($install.elapsed -lt $timeout){
	if ((Get-Service "Sophos MCS Client" -ea SilentlyContinue)){
	Write-Host "Sophos MCS Client Found - Breaking the Loop"
	Break
	}
	start-sleep -seconds 60
}
Write-Host ""
Write-Host "Sophos Setup Completed"

# Verify that Sophos Central Endpoint Agent Installed
Write-Host ""
Write-Host "Verifying that Sophos Central Endpoint installed and is Running"

Get-SophosInstalled
if ($installed -eq "True") {
	Write-Host "--Sophos Central Endpoint Agent Installed Successfully"
	if ($mcsclient.Status -eq "Running"){
	Write-Host "--Sophos MCS Client is Running"
		if ($mcsagent.Status -eq "Running"){
		Write-Host "--Sophos MCS Agent is Running"
		Exit 0
		}
	}
} else {
	Write-Host "--Sophos Central Install Failed"
	Write-Host ""
	Write-Host "Please check the Sophos Central Install Logs for more details"
	Write-Host ""
	Write-Host "Log Location - <system>\programdata\Sophos\Cloudinstaller\Logs\"
	Exit 1
}