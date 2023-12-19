param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

function UpdateSubmodule($path) {
    Write-Host "Updating submodule: $path"

    Push-Location $path

    $isDetached = git symbolic-ref -q HEAD
    if ($null -eq $isDetached) {
        Write-Host "Submodule $path is in a detached HEAD state. Checking for the branch to update."
        $defaultBranch = git remote show origin | Select-String 'HEAD branch' | ForEach-Object { $_ -replace '.*HEAD branch: ', '' }
        Write-Host "Attempting to update to branch: $defaultBranch"
        git checkout $defaultBranch
    }

    git fetch
    git checkout $defaultBranch
    git pull

    $nestedSubmodules = git submodule --quiet foreach 'echo $path'
    foreach ($nestedPath in $nestedSubmodules) {
        UpdateSubmodule $nestedPath
    }

    Pop-Location
}

# Initialize and update submodules
git submodule update --init --recursive

$submodulePaths = git submodule --quiet foreach 'echo $path'
foreach ($path in $submodulePaths) {
    UpdateSubmodule $path
}

git add .
git commit -m "$Message"
git push