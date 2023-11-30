param (
    [string]$FileName
)

if (-not $FileName) {
    Write-Error "-FileName is required."
    exit 1
}

$gitLsFilesOutput = git ls-files $FileName
if ($gitLsFilesOutput -eq $null) {
} else {
    git reset HEAD -- $FileName
}

git rm --force --cached $FileName
Remove-Item $FileName -ErrorAction SilentlyContinue