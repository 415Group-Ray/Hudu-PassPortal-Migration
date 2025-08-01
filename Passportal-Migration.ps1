$workdir = $PSScriptRoot
# --- CONFIGURATION ---
$sensitiveVars = @("PassportalApiKey","PassportalApiKeyId","HuduApiKey","PassPortalHeaders")
$PassportalApiKey = $PassportalApiKey ?? "$(read-host "please enter your PassportalApiKey")"
$PassportalApiKeyId = $PassportalApiKeyId ?? "$(read-host "please enter your PassportalApiKeyId")"
$HuduBaseURL = $HuduBaseURL ?? "$(read-host "please enter your Hudu Base url")"
$HuduAPIKey = $HuduAPIKey ?? "$(read-host "please enter your Hudu API Key")"

# Set-Up
foreach ($file in $(Get-ChildItem -Path ".\helpers" -Filter "*.ps1" -File | Sort-Object Name)) {
    Write-Host "Importing: $($file.Name)" -ForegroundColor DarkBlue
    . $file.FullName
}
$PassPortalHeaders = @{"x-api-key"    = $PassportalApiKey
                       "x-api-key-id" = $PassportalApiKeyId
                       "Content-Type" = "application/json"}
$SelectedLocation = $SelectedLocation ?? $(Select-ObjectFromList -allowNull $false -objects $PPBaseURIs -message "Choose your Location for Passportal API access")
$BaseUri = "https://$($SelectedLocation.APIBase).passportalmsp.com"
Write-Host "using $($selectedLocation.name) / $BaseUri for PassPortal"
Set-Content -Path $logFile -Value "Starting Passportal Migration" 
Set-PrintAndLog -message "Checked Powershell Version... $(Get-PSVersionCompatible)" -Color DarkBlue
Set-PrintAndLog -message "Imported Hudu Module... $(Get-HuduModule)" -Color DarkBlue
Set-PrintAndLog -message "Checked Hudu Credentials... $(Set-HuduInstance)" -Color DarkBlue
Set-PrintAndLog -message "Checked Hudu Version... $(Get-HuduVersionCompatible)" -Color DarkBlue
Set-IncrementedState -newState "Check Source data and get Source Data Options"

$passportalData = @{}

# --- Example usage ---
$folders = Get-FlatPassportalData -Data $(Get-PassportalObjects -objectType "folders")
$folders = Get-FlatPassportalData -Data $(Get-PassportalObjects -objectType "passwords")

Write-Output "Folders: $folders"
Write-Output "Passwords: $passwords"
 

Write-Host "Unsetting vars before next run."
# foreach ($var in $sensitiveVars) {
#     Unset-Vars -varname $var
# }