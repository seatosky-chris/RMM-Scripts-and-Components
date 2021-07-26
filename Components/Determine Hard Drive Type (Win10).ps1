# Pulls the hard drive model from the Get-PhysicalDisk powershell command, and checks if it is a HDD or SSD and saves it to UDF14. This will only work properly on Windows 10 devices. Use the other "Determine Hard Drive Type" component for older devices.

$Customfield="Custom14"
function Write-CustomField {
    param([string]$Value,[string]$Field)
    Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name $Field -Value $Value
}

if (Get-PhysicalDisk | where MediaType -like SSD) {$Disk = "SSD" 
} elseif (Get-PhysicalDisk | where MediaType -like HDD){$Disk = "HDD"
} else { $Disk = "ERROR"}

Write-CustomField -Value $Disk -Field $Customfield	