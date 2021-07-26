# Get the bluebeam license from the registry and write it to userdefined field 7.
Get-ItemProperty "HKLM:\SOFTWARE\Bluebeam Software\Licenses" -Name "Registered" -ErrorAction SilentlyContinue -ErrorVariable KeyError
	If ($KeyError){}
	Else{
		$BluebeamLicense = (Get-ItemProperty HKLM:\SOFTWARE\"Bluebeam Software"\Licenses).Registered
	}

Get-ItemProperty "HKLM:\SOFTWARE\Bluebeam Software\2015\Licenses" -Name "Registered" -ErrorAction SilentlyContinue -ErrorVariable KeyError
	If ($KeyError){}
	Else{
		$BluebeamLicense = (Get-ItemProperty HKLM:\SOFTWARE\"Bluebeam Software"\2015\Licenses).Registered
	}

Get-ItemProperty "HKLM:\SOFTWARE\Bluebeam Software\2016\Licenses" -Name "Registered" -ErrorAction SilentlyContinue -ErrorVariable KeyError
	If ($KeyError){}
	Else{
		$BluebeamLicense = (Get-ItemProperty HKLM:\SOFTWARE\"Bluebeam Software"\2016\Licenses).Registered
	}

Get-ItemProperty "HKLM:\SOFTWARE\Bluebeam Software\2017\Licenses" -Name "Registered" -ErrorAction SilentlyContinue -ErrorVariable KeyError
	If ($KeyError){}
	Else{
		$BluebeamLicense = (Get-ItemProperty HKLM:\SOFTWARE\"Bluebeam Software"\2017\Licenses).Registered
	}

	If($BluebeamLicense){
		New-Item -Path "HKLM:\SOFTWARE\CentraStage" -ErrorAction SilentlyContinue | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name Custom7 -Value $BluebeamLicense -PropertyType STRING -ErrorAction SilentlyContinue | Out-Null
		Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name Custom7 -Value $BluebeamLicense
	}
	Else{
		New-Item -Path "HKLM:\SOFTWARE\CentraStage" -ErrorAction SilentlyContinue | Out-Null
		New-ItemProperty -Path "HKLM:\SOFTWARE\CentraStage" -Name Custom7 -Value "Not Registered" -PropertyType STRING -ErrorAction SilentlyContinue | Out-Null
		Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name Custom7 -Value "Not Registered"
	}