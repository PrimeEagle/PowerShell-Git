param (
    [string]$mappingFilePath
)

if (-not (Test-Path -Path $mappingFilePath)) {
    Write-Error "Mapping file does not exist."
    exit
}
$emailMap = @{}
$nameMap = @{}

Get-Content $mappingFilePath | ForEach-Object {
    $parts = $_ -split ','
    $emailParts = $parts[0] -split '='
    $nameParts = $parts[1] -split '='

    $emailMap[$emailParts[0]] = $emailParts[1]
    $nameMap[$nameParts[0]] = $nameParts[1]
}

$emailMapJson = $emailMap | ConvertTo-Json
$nameMapJson = $nameMap | ConvertTo-Json

git filter-repo --email-callback "emailMap = $emailMapJson; return emailMap.get(original_email, original_email)" `
                --name-callback "nameMap = $nameMapJson; return nameMap.get(original_name, original_name)"
