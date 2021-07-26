### VARIABLES: ###

# Datto API
$ApiParams = @{
    Url        =  '<RMM API URL>'
    Key        =  '<RMM API KEY>'
    SecretKey  =  '<RMM API SECRET KEY>'
}

# Site ID from RMM settings page for csite
$SiteUID = "<SITE UID FROM RMM SETTINGS>"

# Path to the csv of usernames
$UserListPath = "<PATH TO CSV OF USERNAMES>"

# The component ID to run
$ComponentName = "<NAME OF RMM COMPONENT TO RUN>"




### CODE ###
Import-Module DattoRMM -Force
Set-DrmmApiParameters @ApiParams

# Get the user list
$UserList = Import-Csv -Path $UserListPath

# Get the device list and narrow down to windows devices
$DeviceList = Get-DrmmSiteDevices -siteUid $SiteUID
$AcceptableDevices = $DeviceList | Where-Object { $_.deleted -ne "True" -and $_.operatingSystem -like "*Windows*" }

# Get user devices and map to usernames
$UserDevices = @()
$NoComputerFound = @()
$UserCount = 0
foreach ($User in $UserList) {
    $UserCount++
    $Username = $User.Username
    $Devices = $AcceptableDevices | Where-Object { $_.lastLoggedInUser -like "*" + $Username }
    if (($Devices | Measure-Object).Count -gt 0) {
        $UserDevices += @{
            Username = $Username
            Devices = $Devices
        }
    } else {
        $NoComputerFound += $Username
    }
}

# Run quick jobs
$DeviceCount = 0
foreach ($UserDevice in $UserDevices) {s
     $Devices = $UserDevice.Devices
     foreach ($Device in $Devices) {
        $DeviceCount++
        $DeviceUID = $Device.uid
        
       Set-DrmmDeviceQuickJob -deviceUid $DeviceUID -jobName $ComponentName
     }
}

if ($NoComputerFound) {
    $ParsedUsernames = $NoComputerFound | ForEach-Object { ($_.Split("\"))[1] }
    Write-Host "No computer was found for the following users:" $ParsedUsernames -ForegroundColor Red
}

Write-Host "Total users: $UserCount   Devices Updated: $DeviceCount"
