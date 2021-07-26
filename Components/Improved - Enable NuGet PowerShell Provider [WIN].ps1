# Enables Nuget as a powershell provider, and adds the PSGallery as a repository.
# Requires: Windows 10 and up or Server 2012R2 and up, PowerShell 5.0
# Related blog: https://cyberdrain.com

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Import-Module PowerShellGet 
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Write-Host "Installed NuGet"
} catch {
    Write-Host "Failed to install NuGet"
    Write-Error "Failed to install NuGet"
}
try {
    Register-PSRepository -Default
} catch {
    # do nothing
}
try {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Write-Host "`rTrusted PSGallery."
} catch {
    Write-Host "`rFailed to trust PSGallery."
    Write-Error "Failed to trust PSGallery."
}