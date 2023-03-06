###
# File: \Dell - Bios Password Check.ps1
# Project: Custom RMM Components
# Created Date: Tuesday, August 2nd 2022, 10:37:13 am
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

# This checks if a computer has a bios password and sets UDF 16 to true or false depending on the result. This will only work on Dell computers.

$Customfield="Custom16"
function Write-CustomField {
    param([string]$Value,[string]$Field)
    Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name $Field -Value $Value
}

Function Get_Dell_BIOS_Settings
 {
  $WarningPreference='silentlycontinue'
  If (Get-Module -ListAvailable -Name DellBIOSProvider)
   {} 
  Else
   {
    Install-Module -Name DellBIOSProvider -Force
   }
  get-command -module DellBIOSProvider | out-null
  $Script:Get_BIOS_Settings = get-childitem -path DellSmbios:\ | select-object category | 
  foreach {
  get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue 
  } 
   $Script:Get_BIOS_Settings = $Get_BIOS_Settings |  % { New-Object psobject -Property @{
    Setting = $_."attribute"
    Value = $_."currentvalue"
    }}  | select-object Setting, Value 
 } 

Get_Dell_BIOS_Settings

$IsAdminPasswordSet = Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet

if ($IsAdminPasswordSet.CurrentValue -eq "True") {
   Write-CustomField -Value "True" -Field $Customfield
} else {
   Write-CustomField -Value "False" -Field $Customfield
}