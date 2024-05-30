$AutoDocLocations = @(
	"C:\seatosky\AutoDoc",
	"C:\STS\AutoDoc",
	"C:\seatosky\UserAudit",
	"C:\STS\UserAudit",
	"C:\seatosky",
	"C:\STS",
	"C:\AutoDoc",
	"C:\UserAudit"
) # All possible locations to scan, not recursive

write-host "AutoDoc Type Detection"
write-host "==============================================================="

$varString = "AutoDoc Types: "

# an array of AutoDoc types and the acronym we will use for that
$AutoDocTypes = [ordered]@{
	"Active Directory"						= "AD"
	"AD Groups"								= "AD_G"
	"Bluebeam Licensing"					= "BBM_L"
	"Datto Backups"							= "DT_BK"
	"Email - Office365"						= "O365"
	"File Shares - AD Server"				= "FS_AD"
	"File Shares - File Server"				= "FS_FS"
	"File Shares"							= "FS"
	"Firewalls - Sophos"					= "FW_S"
	"Hyper-V"								= "HV"
	"*Licensing Overview"					= "LO"
	"Meraki Licensing"						= "ML"
	"O365 Groups"							= "O365_G"
	"Security"								= "SEC"
	"Warranty"								= "WAR"

	# User Audit
	"User_Billing_Update"               	= "UA"

	# Device Audit
	"DeviceAudit-Automated"					= "DA"
}

# Get all the files in the possible folders
$AllFiles = @()
foreach ($Folder in $AutoDocLocations) {
	$AllFiles += Get-ChildItem -Path $Folder -ErrorAction Ignore
}

# Find AutoDoc types from the files
$AutoDocTypes.GetEnumerator() | ForEach-Object {
	$TypeInfo = $_
	$Matching = $AllFiles.Name | Where-Object { $_ -like "$($TypeInfo.Name).*" }

	if ($Matching -and ($Matching | Measure-Object).Count -gt 0) {
		$varString += ":$($TypeInfo.Value)"
	}
}

write-host "==============================================================="
write-host "- Search Completed."

if ($varString -eq "AutoDoc Types: ") {
	$varString = "AutoDoc Types: None Found"
	Write-Host ": No AutoDoc was found on this device."
} else {
	$varString += ":"
	write-host ": Final list of discovered AutoDoc types:"
	write-host "  [$varString]"
}

@"

At the bottom of this output is a list of the various AutoDoc
types that were checked for alongside the abbreviations used to
denote them, which are what will appear in a UDF if you have
instructed the script to write to one. You can use this data to 
craft a custom Filter to catch devices with a certain AutoDoc.
(Component has been instructed to write to UDF #$env:usrUDF.)

As an example, a server with Active Directory, 
Files Shares - AD Server and the User Audit types running
would produce a UDF that looks like this:
AutoDoc Types: :AD:FS_AD:UA:
===============================================================
"@

# output the list, sorted;
[System.Collections.SortedList]$AutoDocTypes | ft -AutoSize

# write the udf

if ($varString -match '\s\:') {
	New-ItemProperty "HKLM:\Software\CentraStage" -Name "Custom$env:usrUDF" -PropertyType String -Value $varString -force | Out-Null
} else {
	New-ItemProperty "HKLM:\Software\CentraStage" -Name "Custom$env:usrUDF" -PropertyType String -Value "$varString" -force | Out-Null
}