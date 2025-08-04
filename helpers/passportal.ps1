
function Get-PassportalAuthToken {
param (
    [string]$apiKey = $passportalData.APIkeyid,
    [string]$apiSecret = $passportalData.APIkey,
    [string]$identifier,
    [string]$scope = 'global'
)
# Body parameters
$content = "$scope$identifier"
# Construct body
$body = @{
    scope      = $scope
    content    = $content
    identifier = $identifier
} | ConvertTo-Json -Compress

# Create HMAC-SHA256 signature
$utf8Encoding = [System.Text.Encoding]::UTF8
$keyBytes = $utf8Encoding.GetBytes($apiSecret)
$contentBytes = $utf8Encoding.GetBytes($content)
$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = $keyBytes
$hashBytes = $hmac.ComputeHash($contentBytes)
$xHash = [BitConverter]::ToString($hashBytes) -replace '-', '' | ForEach-Object { $_.ToLower() }

# Define headers
$headers = @{
    'x-key'        = $apiKey
    'x-hash'       = $xHash
    'Content-Type' = 'application/json'
}

# Make the request
return $(Invoke-RestMethod -Uri 'https://your.passportal.api/authorization' `
                              -Method Post `
                              -Headers $headers `
                              -Body $body)

}

function Get-PassportalLeafArrays {
    param (
        [Parameter(Mandatory)]
        [object]$Data
    )

    $leafArrays = @()

    if ($Data -is [System.Collections.IEnumerable] -and $Data -notlike '*String*') {
        foreach ($item in $Data) {
            $leafArrays += Get-PassportalLeafArrays -Data $item
        }
    } elseif ($Data -is [PSCustomObject]) {
        $leafArrays += ,$Data
    }

    return $leafArrays
}

# --- MAIN FUNCTION TO FETCH AND FLATTEN ---
function Get-PassportalObjects {
    param (
        [Parameter(Mandatory)][string]$ObjectType
    )

    $uri = "$BaseUri/$($ObjectType.ToLower())"
    Write-Host "Requesting $ObjectType from $uri"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $passportalData.requestHeaders
        $flat = Get-FlatPassportalData -Data $response
        return $flat
    } catch {
        Write-Warning "Failed to get $ObjectType. $_"
        return @()
    }
}

# --- RECURSIVELY FLATTEN TO PSCUSTOMOBJECTS ---
function Get-FlatPassportalData {
    param (
        [object]$Data
    )

    $results = @()

    if ($null -eq $Data) { return @() }

    if ($Data -is [System.Collections.IDictionary] -or $Data -is [PSCustomObject]) {
        return ,$Data
    }
    elseif ($Data -is [System.Collections.IEnumerable] -and $Data -notlike '*String*') {
        foreach ($item in $Data) {
            $results += Get-FlatPassportalData -Data $item
        }
    }

    return $results
}