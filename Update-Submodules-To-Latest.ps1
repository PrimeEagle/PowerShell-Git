param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

Write-Host "WARNING: This script will reset all submodules to their remote states."
Write-Host "All local changes in the submodules will be lost."
Write-Host "Do you want to continue? [Y/N]"

$confirmation = Read-Host
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Script aborted by user."
    exit
}

function UpdateSubmodule($path) {
    Write-Host "Updating submodule: $path"

    git -C $path fetch origin
    git -C $path reset --hard origin/main
    git -C $path clean -fd
    git -C $path submodule update --init --recursive
}

git pull origin main

$submodules = git submodule foreach --quiet --recursive 'echo $path'
foreach ($path in $submodules) {
    UpdateSubmodule $path
}

git add .
git commit -m "$Message"
git push origin main