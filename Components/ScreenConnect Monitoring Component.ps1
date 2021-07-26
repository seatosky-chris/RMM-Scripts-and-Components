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