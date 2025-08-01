

function Get-FlatPassportalData {
    param (
        [object]$Data
    )

    $results = @()

    if ($null -eq $Data) { return @() }

    if ($Data -is [System.Collections.IDictionary] -or $Data -is [PSCustomObject]) {
        # This is a usable object
        return ,$Data
    }
    elseif ($Data -is [System.Collections.IEnumerable] -and $Data -notlike '*String*') {
        foreach ($item in $Data) {
            $results += Flatten-PassportalData -Data $item
        }
    }

    return if ($results) {$results | ConvertTo-Json -Depth 85} else {@()}
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

function Get-PassportalObjects {
    param (
        [string]$objectType
    )
    $uri = "$BaseUri/$objectType".ToLower()
    try {
        write-host "Requesting $objectType from $uri"
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $PassPortalHeaders
        return $(Get-FlatPassportalData $response)
    } catch {
        Write-Error "Failed to get passwords: $_"
    }
}
