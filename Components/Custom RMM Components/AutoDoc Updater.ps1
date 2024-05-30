<# 
Description:
This script can be used to update an AutoDoc script. 
Just upload the latest version of the script as a file (the Live version) and run this script on the server where the AutoDoc script is located.
The script will compare the variables and add any new ones. It will then replace the entire script after the variables with the latest code.
Be sure to set any new variables in the uploaded script to what you want them to be on the server, otherwise you will need to manually update them.

If an existing script cannot be found, this script won't do anything and will exit with an error. 

Variables must be contained between 2 sets of #####'s (a minimum of 10) before and after the variables. 

If there are multiple blocks of variables, set $VariablesBlocks to the amount of blocks there are

If any variables were renamed, you can manually rename them in the "Manually renaming variables" block near the top of this script
#>

$AutoDoc_FileName = "AD Groups"
$VariableBlocks = 1 # The amount of variable blocks (usually 1)

$ExistingPath = "C:\seatosky\AutoDoc\$($AutoDoc_FileName).ps1"
$NewPath = ".\$($AutoDoc_FileName).ps1"

##### 
# Manually renaming variables
# (Get-Content $ExistingPath).Replace('$ITGApiKey', '$APIKEy') | Set-Content $ExistingPath
# (Get-Content $ExistingPath).Replace('$ITGApiEndpoint', '$APIEndpoint') | Set-Content $ExistingPath
###########

$ScriptContents_Existing = Get-Content -Path $ExistingPath -Raw
$ScriptContents_New = Get-Content -Path $NewPath -Raw

if (!$ScriptContents_Existing) {
	Write-Error "Could not find an existing AutoDoc script."
	exit 1
}
if (!$ScriptContents_New) {
	Write-Error "Could not find a new AutoDoc script. Did you upload it?"
	exit 1
}

$Regex_Options = [Text.RegularExpressions.RegexOptions]'Singleline, IgnoreCase'
function UpdateVariable ($NewVar, $AfterVar = $false, $Block = 0) {
	$LineNumber = $false

	if ($AfterVar) {	
		$NextVar = [regex]::Match((Get-Content $ExistingPath -Raw), "($([Regex]::Escape($AfterVar))( =|=)(.*?))((\$[a-zA-Z0-9_-]+?)( =|=)|##########)", $Regex_Options)
		if ($NextVar -and $NextVar.Groups[5].Value -and $NextVar.Groups[5].Value -like "$*") {
			$NextVar = $NextVar.Groups[5].Value
			$FindLine = Get-Content $ExistingPath | Select-String $NextVar -SimpleMatch
			$LineNumber = ($FindLine.LineNumber | Select-Object -First 1) - 1
		} elseif ($NextVar -and $NextVar.Groups[4].Value -and $NextVar.Groups[4].Value -like "#######*") {
			$FindLine = Get-Content $ExistingPath | Select-String "##########" -SimpleMatch | Select-Object -Skip (2*($Block)+1)
			$LineNumber = ($FindLine.LineNumber | Select-Object -First 1) - 1
		} else {
			$AllVars = Get-Content $ExistingPath | Select-String "(\$[a-zA-Z0-9_-]+?)( =|=)|##########"
			$UseNextVar = $false
			$AllVars | ForEach-Object {
				if ($UseNextVar -and ($_ -like "$*" -or $_ -like "#######*")) {
					$LineNumber = ($_.LineNumber | Select-Object -First 1) - 1
					break
				}
				if ($_ -like "$($AfterVar)*") {
					$UseNextVar = $true
				}
			}
		}
	} else {
		$FindLine = Get-Content $ExistingPath | Select-String "##########" -SimpleMatch
		$LineNumber = ($FindLine.LineNumber | Select-Object -First 1 -Skip (2*($Block)))
	}

	$FileContent = Get-Content $ExistingPath
	$FileContent[$LineNumber-1] += ("`n" + $NewVar.Trim())
	$FileContent | Set-Content $ExistingPath
}

for ($i = 0; $i -lt $VariableBlocks; $i++) {
	$Variables_Existing = [regex]::Matches($ScriptContents_Existing,'(#{5,100}.*?#{5,100}|#{10,200})[\n|\r|\r\n](.*?)[\n|\r|\r\n](#{5,100}.*?#{5,100}|#{10,200})', $Regex_Options)[$i].Groups[2].Value
	$Variables_New = [regex]::Matches($ScriptContents_New,'(#{5,100}.*?#{5,100}|#{10,200})[\n|\r|\r\n](.*?)[\n|\r|\r\n](#{5,100}.*?#{5,100}|#{10,200})', $Regex_Options)[$i].Groups[2].Value

	if (!$Variables_Existing -or !$Variables_New) {
		Write-Error "Could not find all variables for comparison. Skipping and just updating the main script."
	} else {
		# Compare and update the script variables
		$LastVar = $false
		$Variables_New.Split([Environment]::NewLine) | ForEach-Object {
			$VarName = [regex]::Match($_, '(\$[a-zA-Z0-9_-]+?)( =|=)').Groups[1].Value
			if ($VarName -and $VarName -notlike '$false' -and $VarName -notlike '$true') {
				if ($Variables_Existing -notlike "*$($VarName)*") {
					# New variable, add it
					$ToAdd = [regex]::Match($Variables_New, "($([Regex]::Escape($VarName))( =|=)(.*?))(\n\$|##########|$)", $Regex_Options)
					$ToAdd_FullVar = $ToAdd.Groups[1].Value
					$ToAdd_ValueOnly = $ToAdd.Groups[3].Value
					if ($ToAdd_FullVar) {
						UpdateVariable -NewVar $ToAdd_FullVar -AfterVar $LastVar -Block $i
						Write-Host "Adding new variable `'$($VarName)`' after variable `'$($LastVar)`' with value: `'$($ToAdd_ValueOnly.Trim())`'"
					} else {
						Write-Error "Failed to add new variable: $VarName"
					}
				}
				$LastVar = $VarName
			}
		}
	}
}

# Now update the script (everything after the variables section)
$ScriptContents_Existing = Get-Content $ExistingPath
$ScriptContents_New = Get-Content -Path $NewPath

$StartingLine_Existing = $false
$FindLine_Existing = $ScriptContents_Existing | Select-String "##########" -SimpleMatch
if ($FindLine_Existing) {
	$LineNumber_Existing = $FindLine_Existing.LineNumber | Select-Object -Skip (2*($VariableBlocks)-1) -First 1
	$StartingLine_Existing = $LineNumber_Existing + 1
}

$StartingLine_New = $false
$FindLine_New = $ScriptContents_New | Select-String "##########" -SimpleMatch
if ($FindLine_New) {
	$LineNumber_New = $FindLine_New.LineNumber | Select-Object -Skip (2*($VariableBlocks)-1) -First 1
	$StartingLine_New = $LineNumber_New + 1
}

if (!$StartingLine_Existing -or !$StartingLine_New) {
	Write-Error "Could not find the end of the variables. Skipping updating the main script."
	exit 1
}

$MaxLines = $ScriptContents_New.Count
$ScriptContents_Update = $ScriptContents_Existing[0..($MaxLines-1)]

$CurLineExisting = $StartingLine_Existing
for ($i = $StartingLine_New; $i -le $MaxLines; $i++) {
	if ($CurLineExisting -gt ($ScriptContents_Existing.Count - 1)) {
		$ScriptContents_Update += $ScriptContents_New[$i]
	} else {
		$ScriptContents_Update[$CurLineExisting] = $ScriptContents_New[$i]
	}
	$CurLineExisting++
}

Set-Content $ExistingPath $ScriptContents_Update
Write-Host "Updated script!"