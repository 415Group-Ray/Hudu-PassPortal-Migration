
function Get-SafeFilename {
    param([string]$Name,
        [int]$MaxLength=25
    )

    # If there's a '?', take only the part before it
    $BaseName = $Name -split '\?' | Select-Object -First 1

    # Extract extension (including the dot), if present
    $Extension = [System.IO.Path]::GetExtension($BaseName)
    $NameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($BaseName)

    # Sanitize name and extension
    $SafeName = $NameWithoutExt -replace '[\\\/:*?"<>|]', '_'
    $SafeExt = $Extension -replace '[\\\/:*?"<>|]', '_'

    # Truncate base name to 25 chars
    if ($SafeName.Length -gt $MaxLength) {
        $SafeName = $SafeName.Substring(0, $MaxLength)
    }

    return "$SafeName$SafeExt"
}

if (-not $PassportalDocsConvert -or -not $true -eq $PassportalDocsConvert){
    Write-host "Not set to convert passportal"; Exit 0;
}

if (-not $PassportalRubooksPath -or $([string]::IsNullOrEmpty($PassportalRubooksPath))){
    $PassportalRubooksPath = $(read-host "Please enter absolute path to your passportal runbooks")
}

if (test-path $PassportalRubooksPath){
    Write-host "$PassportalRunbooksPath is valid"
} else {
    Write-host "$PassportalRunbooksPath is not valid"
    exit 1
}

$ConvertDocsList = Get-ChildItem -Path $(resolve-path -path $PassportalRubooksPath).path `
            -Filter "*.pdf" `
            -File -Recurse -ErrorAction SilentlyContinue

if (-not $ConvertDocsList -or $ConvertDocsList.count -lt 1){
    Write-host "No eligible PDFS for convert."
    exit 1
} else {
    Write-host "$($ConvertDocsList.count) eligible PDFS for convert."
}


$tmpfolder=$(join-path "$($workdir ?? $PSScriptRoot)" "tmp")
foreach ($folder in @($tmpfolder)) {
    if (!(Test-Path -Path "$folder")) { New-Item "$folder" -ItemType Directory }
    Get-ChildItem -Path "$folder" -File -Recurse -Force | Remove-Item -Force
}


$sofficePath=$(Get-LibreMSI -tmpfolder $tmpfolder)

$convertedDocs = @{}

foreach ($a in $ConvertDocsList){
    $Keyname = Get-Safefilename -Name "$($a.Name -replace ".","-")".trim()
    $extractPath = "$tmpfolder\$Keyname"
    if (!(Test-Path -Path "$extractPath")) { New-Item "$extractPath" -ItemType Directory }; Get-ChildItem -Path "$extractPath" -File -Recurse -Force | Remove-Item -Force;
    try {


    } catch {
        Write-Error "Error during slim convert-"
        Convert-PdfToSlimHtml
    }


}