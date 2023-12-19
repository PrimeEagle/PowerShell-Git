param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

function UpdateSubmodule($path) {
    Write-Host "Updating submodule: $path"

    Push-Location $path

    $isDetached = git symbolic-ref -q HEAD
    if ($null -eq $isDetached) {
        Write-Host "Submodule $path is in a detached HEAD state. Attempting to update to the default branch."

        $defaultBranch = "main"
        git checkout $defaultBranch
    }

    git fetch
    git checkout origin/$(git symbolic-ref --short HEAD)

    $nestedSubmodules = git submodule --quiet foreach 'echo $path'
    foreach ($nestedPath in $nestedSubmodules) {
        UpdateSubmodule $nestedPath
    }

    Pop-Location
}

# Update the submodules to the commit specified by the superproject
git submodule update --init --recursive

$submodulePaths = git submodule --quiet foreach 'echo $path'
foreach ($path in $submodulePaths) {
    UpdateSubmodule $path
}

git add .
git commit -m "$Message"
git push
