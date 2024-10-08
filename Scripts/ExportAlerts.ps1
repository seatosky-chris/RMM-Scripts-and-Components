$DattoAPI = @{
	Url        =  '<RMM API URL>'
    Key        =  '<RMM API KEY>'
    SecretKey  =  '<RMM API SECRET KEY>'
}
$DattoAPIRegion = "zinfandel"

Import-Module DattoRMM -Force
Set-DrmmApiParameters @DattoAPI

$Alerts = Get-DrmmAccountAlertsOpen

$PrettyAlerts = [System.Collections.ArrayList]@()
$LocalAdminAlerts = $Alerts | Where-Object { [bool]($_.alertContext.samples.PSObject.Properties.name -contains "Local Admins") }

foreach ($Alert in $LocalAdminAlerts) {
	$PrettyAlerts.Add([PSCustomObject]@{
		Device = $Alert.alertSourceInfo.deviceName
		Company = $Alert.alertSourceInfo.siteName
		"Device Link" = "https://$($DattoAPIRegion).centrastage.net/csm/search?qs=uid%3A$($Alert.alertSourceInfo.deviceUid)"
		"Admin Users" = $Alert.alertContext.samples."Local Admins".TrimStart("BAD (").TrimEnd(")")
		"Alert Link" = "https://zinfandel.centrastage.net/csm/monitor/alertDetailsAjax/$($Alert.alertUid)"
	})
}

Remove-Item "C:\Temp\LocalAdminAlerts.xlsx"
$PrettyAlerts | Sort-Object -Property Company, Device | Export-Excel "C:\Temp\LocalAdminAlerts.xlsx" -WorksheetName "Local Admin Alerts" -AutoSize -AutoFilter -NoNumberConversion * -TableName "LocalAdminAlerts" -Title "Local Admin Alerts" -TitleBold -TitleSize 18

