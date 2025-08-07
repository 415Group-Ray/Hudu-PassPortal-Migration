
function Get-PassportalAuthToken {
    param (
        [string]$scope = 'docs_api',
        [string]$presharedSecret = "aUa&&XUQBJXz2x&"
    )
    $SHAObject = New-Object System.Security.Cryptography.HMACSHA256
    $SHAObject.key = [Text.Encoding]::ASCII.GetBytes($passportalData.APIkeyId)
    $signature = $SHAObject.ComputeHash([Text.Encoding]::ASCII.GetBytes($PresharedSecret))
    $StringifiedHash = [System.BitConverter]::ToString($signature).Replace('-', '').ToLower()
    $response = Invoke-RestMethod -Headers @{'X-KEY'  = $passportalData.APIkey; 'X-HASH' = $StringifiedHash} `
                -Uri "https://$($selectedLocation.APIBase).passportalmsp.com/api/v2/auth/client_token" -Method POST `
                -Body @{'content' = $PresharedSecret; 'scope'   = "$scope"} `
                -ContentType "application/x-www-form-urlencoded"
    write-host "Authentication Result $(if ($response -and $response.success -and $true -eq $response.success) {'Successful'} else {'Failure'})"

    return @{
        token   = $response.access_token
        refresh_token = $response.refresh_token
        headers = @{ 'x-access-token' = $response.access_token }
    }

}

function ConvertTo-QueryString {
    param (
        [Parameter(Mandatory)]
        [hashtable]$QueryParams
    )

    return ($QueryParams.GetEnumerator() | ForEach-Object {
        "$([uri]::EscapeDataString($_.Key))=$([uri]::EscapeDataString($_.Value))"
    }) -join '&'
}

function Get-PassportalObjects {
    param (
        [Parameter(Mandatory)][string]$resource
    )

    $uri = "$($passportalData.BaseURL)api/v2/$resource"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $passportalData.Headers
        return $response
    } catch {
        Write-Warning "Error fetching $uri $($_.Exception.Message)"
        return $null
    }
}

function Get-CSVExportData {
    param (
        [string]$exportsFolder
    )

    Write-Host "Checking .\exported-csvs folder for Passportal exports..."
    foreach ($file in Get-ChildItem -Path $exportsFolder -Filter "*.csv" -File | Sort-Object Name) {
        Write-Host "Importing: $($file.Name)" -ForegroundColor DarkBlue

        $fullPath = $file.FullName
        $firstLine = (Get-Content -Path $fullPath -TotalCount 1).Trim()

        # Check if the first line appears to be a header
        $hasHeader = $firstLine -match 'PassPortal ID'

        if ($file.Name -like "*clients.csv") {
            $csv = if ($hasHeader) {
                Import-Csv -Path $fullPath
            } else {
                Import-Csv -Path $fullPath -Header "PassPortal ID","Name","Email"
            }
            $passportalData.csvData['clients'] = $csv
        } elseif ($file.Name -like "*passwords.csv") {
            $csv = if ($hasHeader) {
                Import-Csv -Path $fullPath
            } else {
                Import-Csv -Path $fullPath -Header "Passportal ID","Client Name","Credential","Username","Password","Description","Expires (Yes/No)","Notes","URL","Folder(Optional)"
            }
            $passportalData.csvData['passwords'] = $csv
        } elseif ($file.Name -like "*users.csv") {
            $csv = if ($hasHeader) {
                Import-Csv -Path $fullPath
            } else {
                Import-Csv -Path $fullPath -Header "Passportal ID (BLANK)","Last Name","First Name","Email","Phone"

            }
            $passportalData.csvData['users'] = $csv
        } elseif ($file.Name -like "*vault.csv") {
            $csv = if ($hasHeader) {
                Import-Csv -Path $fullPath
            } else {
                Import-Csv -Path $fullPath -Header "Passportal ID","Credential","Username","Password","Description","Expires (Yes/No)","Notes","URL","Folder(Optional)"
            }
            $passportalData.csvData['vault'] = $csv
        }        
    }

}