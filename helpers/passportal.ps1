
function Get-PassportalFolders {
    $uri = "$BaseUri/folders"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $PassPortalHeaders
        return $response
    } catch {
        Write-Error "Failed to get folders: $_"
    }
}

function Get-PassportalPasswords {
    $uri = "$BaseUri/passwords"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $PassPortalHeaders
        return $response
    } catch {
        Write-Error "Failed to get passwords: $_"
    }
}