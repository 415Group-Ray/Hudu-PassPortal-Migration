function Get-HmacSha256Hex {
    param (
        [string]$Message,
        [string]$Secret
    )

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($Secret)

    $hashBytes = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Message))
    return [BitConverter]::ToString($hashBytes) -replace '-', '' | ForEach-Object { $_.ToLower() }
}
function Get-PassportalAuthToken {
    param (
        [string]$apiKey,
        [string]$apiSecret,
        [string]$identifier,
        [string]$scope = 'global'
    )

    $content = "$scope$identifier"

    $hash = Get-HmacSha256Hex -Message $content -Secret $apiSecret
    Write-Host "x-hash: $hash"
    Write-Host "x-key:  $apiKey"
    Write-Host "content: $content"

    # Build JSON body
    $body = @{
        scope      = $scope
        identifier = $identifier
        content    = $content
    } | ConvertTo-Json -Compress

    # Headers for request
    $headers = @{
        'x-key'        = $apiKey
        'x-hash'       = $hash
        'Content-Type' = 'application/json'
    }

    # Send request
    $response = Invoke-RestMethod -Uri "https://us-clover.passportalmsp.com/api/v2/auth/client_token" `
                                -Method Post `
                                -Headers $headers `
                                -Body $body
    return @{
        token   = $response.token
        headers = $headers
    }
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

    $uri = "$($passportalData.BaseURL)/$($ObjectType.ToLower())"
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