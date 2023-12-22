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

    Push-Location $path

    git checkout main
    git fetch origin
    git reset --hard origin/main
    git clean -fd
    git submodule update --init --recursive

    $changes = git status --porcelain
    if ($changes) {
        git add .
        git commit -m "Update submodule $path and its nested submodules"
    }

    $nestedSubmodules = git submodule foreach --recursive --quiet 'echo $path'
    foreach ($nestedPath in $nestedSubmodules) {
        UpdateSubmodule $nestedPath

        $nestedChanges = git status --porcelain
        if ($nestedChanges) {
            git add .
            git commit -m "Update nested submodule $nestedPath"
        }
    }

    Pop-Location
}

git pull origin main
git submodule update --init --recursive
$submodulePaths = git submodule foreach --recursive --quiet 'echo $path'

foreach ($path in $submodulePaths) {
    UpdateSubmodule $path
}

git add .
git commit -m "$Message"
git push origin main