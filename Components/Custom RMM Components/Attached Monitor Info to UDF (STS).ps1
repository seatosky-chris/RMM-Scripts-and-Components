###
# File: \Attached Monitor Info to UDF (STS).ps1
# Project: Custom RMM Components
# Created Date: Friday, May 12th 2023, 9:50:16 am
# Author: Chris Jantzen
# -----
# Last Modified: Fri Jun 30 2023
# Modified By: Chris Jantzen
# -----
# Copyright (c) 2023 Sea to Sky Network Solutions
# License: MIT License
# -----
# 
# HISTORY:
# Date      	By	Comments
# ----------	---	----------------------------------------------------------
# 2023-05-12	CJ	Built the initial script. This is a combination of MaxAnderson95's script found here: https://github.com/MaxAnderson95/Get-Monitor-Information/blob/master/Get-Monitor.ps1
#						and a combination of code from Michael_McCool, Yottabyte, Andrew_Percy, Terabyte, tsd-aaron, and Bit found here: https://community.datto.com/t5/Community-ComStore/WIN-PS-Detect-Attached-Monitors/m-p/82529
###

<#

	.SYNOPSIS
	This powershell function gets information about the monitors attached to any computer. It uses EDID information provided by WMI. If this value is not specified it pulls the monitors of the computer that the script is being run on.

	.DESCRIPTION
	The function begins by looping through each computer specified. For each computer it gets a litst of monitors.
	It then gets all of the necessary data from each monitor object and converts and cleans the data and places it in a custom PSObject. It then adds
	the data to an array. At the end the array is displayed.

	.PARAMETER ComputerName
	Use this to specify the computer(s) which you'd like to retrieve information about monitors from.

	.EXAMPLE
	PS C:/> Get-Monitor.ps1 -ComputerName SSL1-F1102-1G2Z

	Manufacturer Model    SerialNumber AttachedComputer
	------------ -----    ------------ ----------------
	HP           HP E241i CN12345678   SSL1-F1102-1G2Z 
	HP           HP E241i CN91234567   SSL1-F1102-1G2Z 
	HP           HP E241i CN89123456   SSL1-F1102-1G2Z

	.EXAMPLE
	PS C:/> $Computers = @("SSL7-F108F-9D4Z","SSL1-F1102-1G2Z","SSA7-F1071-0T7F")
	PS C:/> Get-Monitor.ps1 -ComputerName $Computers

	Manufacturer Model      SerialNumber AttachedComputer
	------------ -----      ------------ ----------------
	HP           HP LA2405x CN12345678   SSL7-F108F-9D4Z
	HP           HP E241i   CN91234567   SSL1-F1102-1G2Z 
	HP           HP E241i   CN89123456   SSL1-F1102-1G2Z 
	HP           HP E241i   CN78912345   SSL1-F1102-1G2Z
	HP           HP ZR22w   CN67891234   SSA7-F1071-0T7F

#>


[CmdletBinding()]
PARAM (
	[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
	[String[]]$ComputerName = $env:ComputerName
)

# List of All in One model types to ignore
$AllInOneModels = @("*800 AIO*", "*8300 AiO*", "OptiPlex*", "HDMI Extender")

# List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later down.
$ManufacturerHash = @{ 
	"AAC" =	"AcerView";
    "ACI" = "ASUS";
	"ACR" = "Acer";
	"AOC" = "AOC";
    "AOP" = "AOpen";
	"AIC" = "AG Neovo";
	"APP" = "Apple";
	"AST" = "AST Research";
	"AUO" = "ASUS";
    "AUS" = "ASUS";
	"BNQ" = "BenQ";
	"CMO" = "Acer";
	"CPL" = "Compal";
	"CPQ" = "Compaq";
	"CPT" = "Chunghwa Picture Tubes";
	"CTX" = "CTX";
	"DEC" = "DEC";
	"DEL" = "Dell";
	"DPC" = "Delta";
	"DWE" = "Daewoo";
	"EIZ" = "EIZO";
    "ELO" = "Elo";
	"ELS" = "ELSA";
	"ENC" = "EIZO";
	"EPI" = "Envision";
	"FCM" = "Funai";
	"FUJ" = "Fujitsu";
	"FUS" = "Fujitsu-Siemens";
    "GBT" = "Gigabyte";
	"GSM" = "LG";
    "GWD" = "Arzopa";
	"GWY" = "Gateway 2000";
	"HEI" = "Hyundai";
	"HIT" = "Hyundai";
    "HPN" = "HP";
	"HSL" = "Hansol";
	"HTC" = "Hitachi/Nissei";
	"HWP" = "HP";
	"IBM" = "IBM";
	"ICL" = "Fujitsu";
	"IVM" = "Iiyama";
	"KDS" = "Korea Data Systems";
    "KTC" = "KTC";
	"LEN" = "LENOVO";
	"LGD" = "ASUS";
	"LPL" = "Fujitsu";
	"MAX" = "Belinea"; 
	"MEI" = "Panasonic";
	"MEL" = "Mitsubishi Electronics";
	"MS_" = "Panasonic";
	"NAN" = "Nanao";
	"NEC" = "NEC";
	"NOK" = "Nokia Data";
	"NVD" = "Fujitsu";
    "ONN" = "ONN";
	"OPT" = "Optoma";
	"PHL" = "Philips";
	"REL" = "Relisys";
	"SAN" = "Samsung";
	"SAM" = "Samsung";
	"SBI" = "Smarttech";
	"SGI" = "SGI";
    "SHP" = "Sharp";
	"SNY" = "Sony";
	"SRC" = "Shamrock";
	"SUN" = "Sun Microsystems";
	"SEC" = "Hewlett-Packard";
	"TAT" = "Tatung";
	"TOS" = "TOSHIBA";
	"TSB" = "TOSHIBA";
    "VIZ" = "Vizio"
	"VSC" = "ViewSonic";
	"ZCM" = "Zenith";
	"UNK" = "Unknown";
	"_YV" = "Fujitsu";
}

function Get-MonitorConnectionType ($Connector) {
    switch ($Connector) {
        '-2' {'Uninitialized'} 
        '-1' {'Other'}
        0 {'VGA'}
        1 {'SVideo'}
        2 {'Composite'}
        3 {'Component'}
        4 {'DVI'}
        5 {'HDMI'}
        6 {'LVDS'}
        8 {'D_JPN'}
        9 {'SDI'}
        10 {'DisplayPort'}
        11 {'DisplayPort (Embedded)'}
        12 {'UDI'}
        13 {'UDI (Embedded)'}
        14 {'SD TV Dongle'}
        15 {'Miracast'}
        16 {'Indirect Wired'}
        2147483648 {'Internal'}
        '0x80000000,' {'Internal'}
        'SVIDEO,' {'SVideo (4/7 Pin)'}
        'COMPOSITE_VIDEO' {'RF'}
        'COMPONENT_VIDEO' {'RCA/BNC'}
        default {"Unknown: $_"}
    }
}

function Format-ManufacturerName ($Manufacturer) {
	if ($Manufacturer) {
		if ($Manufacturer -like "*/*") {
			$Manufacturer = ($Manufacturer -split '/')[0]
		}
		$Manufacturer = $Manufacturer.Trim()
		$Manufacturer = $Manufacturer -replace ",? ?(Inc\.?$|Corporation$|Corp\.?$|Co\.$|Ltd\.?$)", ""
		$Manufacturer = $Manufacturer.Trim()
		$Manufacturer = $Manufacturer -replace ",? ?(Inc\.?$|Corporation$|Corp\.?$|Co\.$|Ltd\.?$)", ""
		$Manufacturer = $Manufacturer.Trim()
		return $Manufacturer
	} else {
		return $null
	}
}

# Take care of special characters in JSON (see json.org), such as newlines, backslashes
# carriage returns and tabs.
# '\\(?!["/bfnrt]|u[0-9a-f]{4})'
function FormatString {
    param(
        [String] $String)
    # removed: #-replace '/', '\/' `
    # This is returned 
    $String -replace '\\', '\\' -replace '\n', '\n' `
        -replace '\u0008', '\b' -replace '\u000C', '\f' -replace '\r', '\r' `
        -replace '\t', '\t' -replace '"', '\"'
}

# Meant to be used as the "end value". Adding coercion of strings that match numerical formats
# supported by JSON as an optional, non-default feature (could actually be useful and save a lot of
# calculated properties with casts before passing..).
# If it's a number (or the parameter -CoerceNumberStrings is passed and it 
# can be "coerced" into one), it'll be returned as a string containing the number.
# If it's not a number, it'll be surrounded by double quotes as is the JSON requirement.
function GetNumberOrString {
    param(
        $InputObject)
    if ($InputObject -is [System.Byte] -or $InputObject -is [System.Int32] -or `
        ($env:PROCESSOR_ARCHITECTURE -imatch '^(?:amd64|ia64)$' -and $InputObject -is [System.Int64]) -or `
        $InputObject -is [System.Decimal] -or $InputObject -is [System.Double] -or `
        $InputObject -is [System.Single] -or $InputObject -is [long] -or `
        ($Script:CoerceNumberStrings -and $InputObject -match $Script:NumberRegex)) {
        Write-Verbose -Message "Got a number as end value."
        "$InputObject"
    }
    else {
        Write-Verbose -Message "Got a string as end value."
        """$(FormatString -String $InputObject)"""
    }
}

function ConvertToJsonInternal {
    param(
        $InputObject, # no type for a reason
        [Int32] $WhiteSpacePad = 0)
    [String] $Json = ""
    $Keys = @()
    Write-Verbose -Message "WhiteSpacePad: $WhiteSpacePad."
    if ($null -eq $InputObject) {
        Write-Verbose -Message "Got 'null' in `$InputObject in inner function"
        $null
    }
    elseif ($InputObject -is [Bool] -and $InputObject -eq $true) {
        Write-Verbose -Message "Got 'true' in `$InputObject in inner function"
        $true
    }
    elseif ($InputObject -is [Bool] -and $InputObject -eq $false) {
        Write-Verbose -Message "Got 'false' in `$InputObject in inner function"
        $false
    }
    elseif ($InputObject -is [HashTable]) {
        $Keys = @($InputObject.Keys)
        Write-Verbose -Message "Input object is a hash table (keys: $($Keys -join ', '))."
    }
    elseif ($InputObject.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
        $Keys = @(Get-Member -InputObject $InputObject -MemberType NoteProperty |
            Select-Object -ExpandProperty Name)
        Write-Verbose -Message "Input object is a custom PowerShell object (properties: $($Keys -join ', '))."
    }
    elseif ($InputObject.GetType().Name -match '\[\]|Array') {
        Write-Verbose -Message "Input object appears to be of a collection/array type."
        Write-Verbose -Message "Building JSON for array input object."
        #$Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "[`n" + (($InputObject | ForEach-Object {
        $Json += "[`n" + (($InputObject | ForEach-Object {
            if ($null -eq $_) {
                Write-Verbose -Message "Got null inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "null"
            }
            elseif ($_ -is [Bool] -and $_ -eq $true) {
                Write-Verbose -Message "Got 'true' inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "true"
            }
            elseif ($_ -is [Bool] -and $_ -eq $false) {
                Write-Verbose -Message "Got 'false' inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "false"
            }
            elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" -or $_.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Found array, hash table or custom PowerShell object inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 4)) -replace '\s*,\s*$' #-replace '\ {4}]', ']'
            }
            else {
                Write-Verbose -Message "Got a number or string inside array."
                $TempJsonString = GetNumberOrString -InputObject $_
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + $TempJsonString
            }
        #}) -join ",`n") + "`n],`n"
        }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4)))],`n"
    }
    else {
        Write-Verbose -Message "Input object is a single element (treated as string/number)."
        GetNumberOrString -InputObject $InputObject
    }
    if ($Keys.Count) {
        Write-Verbose -Message "Building JSON for hash table or custom PowerShell object."
        $Json += "{`n"
        foreach ($Key in $Keys) {
            # -is [PSCustomObject]) { # this was buggy with calculated properties, the value was thought to be PSCustomObject
            if ($null -eq $InputObject.$Key) {
                Write-Verbose -Message "Got null as `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": null,`n"
            }
            elseif ($InputObject.$Key -is [Bool] -and $InputObject.$Key -eq $true) {
                Write-Verbose -Message "Got 'true' in `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": true,`n"            }
            elseif ($InputObject.$Key -is [Bool] -and $InputObject.$Key -eq $false) {
                Write-Verbose -Message "Got 'false' in `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": false,`n"
            }
            elseif ($InputObject.$Key -is [HashTable] -or $InputObject.$Key.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
                Write-Verbose -Message "Input object's value for key '$Key' is a hash table or custom PowerShell object."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ($WhiteSpacePad + 4))"
                $Json += ConvertToJsonInternal -InputObject $InputObject.$Key -WhiteSpacePad ($WhiteSpacePad + 4)
            }
            elseif ($InputObject.$Key.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Input object's value for key '$Key' has a type that appears to be a collection/array."
                Write-Verbose -Message "Building JSON for ${Key}'s array value."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 4))[`n" + (($InputObject.$Key | ForEach-Object {
                    #Write-Verbose "Type inside array inside array/hash/PSObject: $($_.GetType().FullName)"
                    if ($null -eq $_) {
                        Write-Verbose -Message "Got null inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "null"
                    }
                    elseif ($_ -is [Bool] -and $_ -eq $true) {
                        Write-Verbose -Message "Got 'true' inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "true"
                    }
                    elseif ($_ -is [Bool] -and $_ -eq $false) {
                        Write-Verbose -Message "Got 'false' inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "false"
                    }
                    elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" `
                        -or $_.GetType().Name -match '\[\]|Array') {
                        Write-Verbose -Message "Found array, hash table or custom PowerShell object inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 8)) -replace '\s*,\s*$'
                    }
                    else {
                        Write-Verbose -Message "Got a string or number inside inside array."
                        $TempJsonString = GetNumberOrString -InputObject $_
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $TempJsonString
                    }
                }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4) + 4 ))],`n"
            }
            else {
                Write-Verbose -Message "Got a string inside inside hashtable or PSObject."
                # '\\(?!["/bfnrt]|u[0-9a-f]{4})'
                $TempJsonString = GetNumberOrString -InputObject $InputObject.$Key
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": $TempJsonString,`n"
            }
        }
        $Json = $Json -replace '\s*,$' # remove trailing comma that'll break syntax
        $Json += "`n" + " " * $WhiteSpacePad + "},`n"
    }
    $Json
}

# For user on older devices that don't have a version of Powershell with the ConvertTo-Json command
function ConvertTo-STJson {
    [CmdletBinding()]
    #[OutputType([Void], [Bool], [String])]
    param(
        [AllowNull()]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $InputObject,
        [Switch] $Compress,
        [Switch] $CoerceNumberStrings = $false)
    begin{
        $JsonOutput = ""
        $Collection = @()
        # Not optimal, but the easiest now.
        [Bool] $Script:CoerceNumberStrings = $CoerceNumberStrings
        [String] $Script:NumberRegex = '^-?\d+(?:(?:\.\d+)?(?:e[+\-]?\d+)?)?$'
        #$Script:NumberAndValueRegex = '^-?\d+(?:(?:\.\d+)?(?:e[+\-]?\d+)?)?$|^(?:true|false|null)$'
    }
    process {
        # Hacking on pipeline support ...
        if ($_) {
            Write-Verbose -Message "Adding object to `$Collection. Type of object: $($_.GetType().FullName)."
            $Collection += $_
        }
    }
    end {
        if ($Collection.Count) {
            Write-Verbose -Message "Collection count: $($Collection.Count), type of first object: $($Collection[0].GetType().FullName)."
            $JsonOutput = ConvertToJsonInternal -InputObject ($Collection | ForEach-Object { $_ })
        }
        else {
            $JsonOutput = ConvertToJsonInternal -InputObject $InputObject
        }
        if ($null -eq $JsonOutput) {
            Write-Verbose -Message "Returning `$null."
            return $null # becomes an empty string :/
        }
        elseif ($JsonOutput -is [Bool] -and $JsonOutput -eq $true) {
            Write-Verbose -Message "Returning `$true."
            [Bool] $true # doesn't preserve bool type :/ but works for comparisons against $true
        }
        elseif ($JsonOutput-is [Bool] -and $JsonOutput -eq $false) {
            Write-Verbose -Message "Returning `$false."
            [Bool] $false # doesn't preserve bool type :/ but works for comparisons against $false
        }
        elseif ($Compress) {
            Write-Verbose -Message "Compress specified."
            (
                ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
                    -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
            ) -replace ( # these next lines compress ...
                '(?m)^\s*("(?:\\"|[^"])+"): ((?:"(?:\\"|[^"])+")|(?:null|true|false|(?:' + `
                    $Script:NumberRegex.Trim('^$') + `
                    ')))\s*(?<Comma>,)?\s*$'), "`${1}:`${2}`${Comma}`n" `
              -replace '(?m)^\s*|\s*\z|[\r\n]+'
        }
        else {
            ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
                -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
        }
    }
}


# Setup UDF, you can either hard code it here or have it customizable as a variable in the component

# $ENV:UDFnumber = 3 # 1-30
if (!($ENV:UDFnumber)) {
    Write-Output "Please define a custom UDF number!"
    Exit 1
}

  
# Takes each computer specified and runs the following code:
foreach ($Computer in $ComputerName) {

	# Grabs the Monitor objects from WMI
	try {
		$Monitors = Get-CimInstance -NameSpace root\wmi -ClassName WmiMonitorId -ComputerName $Computer -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	} catch { $Monitors = $false }
	try {
		$MonitorConnections = Get-CimInstance -NameSpace root\wmi -ClassName WmiMonitorConnectionParams -ComputerName $Computer -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	} catch { $MonitorConnections = $false }

	# Fallback
	if (!$Monitors) {
		$Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	}
	if (!$MonitorConnections) {
		$MonitorConnections = Get-WmiObject -NameSpace "root\WMI" -Class "WmiMonitorConnectionParams" -ComputerName $Computer -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	}
	if (!$Monitors -and $Computer -eq $env:ComputerName) {
		$Monitors = Get-CimInstance -NameSpace root\wmi -ClassName WmiMonitorId -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	}
	if (!$MonitorConnections -and $Computer -eq $env:ComputerName) {
		$MonitorConnections = Get-CimInstance -NameSpace root\wmi -ClassName WmiMonitorConnectionParams -Filter "Active = '$true'" -ErrorAction SilentlyContinue
	}
	if (!$Monitors -and $MonitorConnections) {
		$Monitors = $MonitorConnections
	}
	if (!$Monitors -and $Computer -eq $env:ComputerName) {
		$Monitors = $(wmic desktopmonitor get "MonitorType,MonitorManufacturer,PNPDeviceID,SystemName" /format:csv) | ConvertFrom-Csv
	}

    # Creates an empty array to hold the data
    $Monitor_Array = @()
	$Monitor_Array_UDF = @()
    
    
    # Takes each monitor object found and runs the following code:
    foreach ($Monitor in $Monitors) {
		
		$MonitorConnection = $MonitorConnections | Where-Object { $_.InstanceName -like $Monitor.InstanceName }
      
		# Defaults
		$Mon_Model = $null
		$Mon_Serial_Number = 0
		$Mon_Manufacturer = $null
		$Mon_Year_of_Manufacture = $null
		$Mon_Display_Type = "Unknown"

		# Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
		if ($Monitor.UserFriendlyName -and [System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
			$Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
		} elseif ($Monitor.InstanceName) {
			$NameParts = $Monitor.InstanceName -split "\\"
			if ($NameParts[1]) {
				$Mon_Model = $NameParts[1]
			} else {
				$Mon_Model = $Monitor.InstanceName
			}
		} elseif ($Monitor.PNPDeviceID) {
			$NameParts = $Monitor.PNPDeviceID.Trim() -split "\\"
			if ($NameParts[1]) {
				$Mon_Model = $NameParts[1]
			} else {
				$Mon_Model = $Monitor.PNPDeviceID
			}
		}
		if ($Monitor.SerialNumberID) {
			$Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
		}
		if ($Monitor.ManufacturerName) {
			$Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
		} elseif ($Monitor.MonitorManufacturer -and $Monitor.MonitorManufacturer -notlike "*Standard monitor types*") {
			$Mon_Manufacturer = $Monitor.MonitorManufacturer.Trim()
		}
		if ($Monitor.YearOfManufacture) {
			$Mon_Year_of_Manufacture = $Monitor.YearOfManufacture
		}
		if ($Monitor.PSComputerName) {
			$Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
		} elseif ($Monitor.SystemName) {
			$Mon_Attached_Computer = $Monitor.SystemName.Trim()
		} else {
			$Mon_Attached_Computer = $Computer
		}
		if ($MonitorConnection -and $MonitorConnection.VideoOutputTechnology) {
			$VideoOutput = $MonitorConnection.VideoOutputTechnology
			$Mon_Display_Type = Get-MonitorConnectionType $VideoOutput
		} elseif ($Monitor.MonitorType) {
			$Mon_Display_Type = $Monitor.MonitorType.Trim()
		}

		# Filters out "non monitors". These are all-in-one computers with built in displays & HDMI extenders. You can add other models to filter out into $AllInOneModels
		if (($AllInOneModels | ForEach-Object { $Mon_Model -like $_ } | Where-Object { $_ } | Measure-Object).count -gt 0) { continue; }

		# Filters out useless Default Monitors with no info
		if ($Mon_Model -like "DEFAULT_MONITOR" -and $Mon_Serial_Number -eq 0 -and !$Mon_Manufacturer -and 
			!$Mon_Year_of_Manufacture -and ($Mon_Display_Type -like "Generic*" -or $Mon_Display_Type -like "Unknown*")
		) { continue; }
		
		# Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
		$Mon_Manufacturer_Friendly = $null
		if ($Mon_Manufacturer) {
			$Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
			if ($null -eq $Mon_Manufacturer_Friendly) {
				$Mon_Manufacturer_Friendly = $Mon_Manufacturer
			}
		}
		
		# Creates a custom monitor object and fills it with 6 NoteProperty members and the respective data
		$Monitor_Obj = [PSCustomObject]@{
			Manufacturer     = Format-ManufacturerName $Mon_Manufacturer_Friendly
			Model            = $Mon_Model
			SerialNumber     = $Mon_Serial_Number
			DisplayType		 = $Mon_Display_Type
			YearOfManufacture = $Mon_Year_of_Manufacture
			AttachedComputer = $Mon_Attached_Computer
		}

		$Monitor_Obj_UDF = [PSCustomObject]@{
			Mftr		 = Format-ManufacturerName $Mon_Manufacturer_Friendly
			Mdl	 	 = $Mon_Model
			SN		 = $Mon_Serial_Number
			Type 	 = if ($Mon_Display_Type -like "Unknown*" -or $Mon_Display_Type -like "Generic*") { "NA" } else { $Mon_Display_Type }
			ManYr	 = $Mon_Year_of_Manufacture
		}
		
		# Appends the object to the array
		$Monitor_Array += $Monitor_Obj
		$Monitor_Array_UDF += $Monitor_Obj_UDF

    } # End foreach Monitor

	if ($Computer -eq $env:ComputerName) {
		# Update UDF
		$DataStamp = Get-date -Format "yyyy-MM-dd"
		try {
			$UDFOutput = "$($Monitor_Array_UDF | ConvertTo-Json -Compress) |Updated: $DataStamp"
		} catch {
			$UDFOutput = "$($Monitor_Array_UDF | ConvertTo-STJson -Compress) |Updated: $DataStamp"
		}

        if ($UDFOutput.length -gt 254) {
            $Monitor_Array_UDF = $Monitor_Array_UDF | Where-Object { $_.SN -and $_.SN -ne 0 }
            try {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-Json -Compress) |Updated: $DataStamp"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-STJson -Compress) |Updated: $DataStamp"
            }
        }

        if ($UDFOutput.length -gt 254) {
            $Monitor_Array_UDF = $Monitor_Array_UDF | Where-Object { $_.Type -and $_.Type -notlike 'Uninitialized' -and $_.Type -notlike 'Other' -and $_.Type -notlike 'Internal' -and $_.Type -notlike 'Default Monitor' -and $_.Type -notlike "Unknown*" -and $_.Type -notlike "NA" }
            try {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-Json -Compress) |Updated: $DataStamp"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-STJson -Compress) |Updated: $DataStamp"
            }
        }

        if ($UDFOutput.length -gt 254) {
            try {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-Json -Compress)"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | ConvertTo-STJson -Compress)"
            }
        }

        if ($UDFOutput.length -gt 254) {
            try {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mftr, Mdl, SN, ManYr | ConvertTo-Json -Compress)"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mftr, Mdl, SN, ManYr | ConvertTo-STJson -Compress)"
            }
        }

        if ($UDFOutput.length -gt 254) {
            try {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mftr, Mdl, SN | ConvertTo-Json -Compress)"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mftr, Mdl, SN | ConvertTo-STJson -Compress)"
            }
        }

        if ($UDFOutput.length -gt 254) {
            try {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mdl, SN | ConvertTo-Json -Compress)"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF | Select-Object -Property Mdl, SN | ConvertTo-STJson -Compress)"
            }
        }

        if ($UDFOutput.length -gt 254) {
            try {
                $UDFOutput = "$($Monitor_Array_UDF.SN | ConvertTo-Json -Compress)"
            } catch {
                $UDFOutput = "$($Monitor_Array_UDF.SN | ConvertTo-STJson -Compress)"
            }
        }

        if ($UDFOutput.length -gt 254) {
            Write-Host "Monitor Array UDF will be truncated as it is over 254 characters long."
            Write-Warning "Monitor Array UDF will be truncated as it is over 254 characters long."
        }

		if (!(Test-Path "HKLM:\SOFTWARE\CentraStage")) { 
			[void](New-Item -Path "HKLM:\SOFTWARE\CentraStage" -Force) 
		}
		[void](New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name "Custom$($ENV:UDFnumber)" -Value "$UDFOutput" -Force)
	}

	# Outputs the Array
    $Monitor_Array
    
} # End foreach Computer