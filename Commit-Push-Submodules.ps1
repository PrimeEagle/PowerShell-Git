param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

function ProcessSubmodule($path, $basePath) {
    Write-Host "Processing submodule: $path"

    # Construct the full path to the submodule
    $fullPath = Join-Path $basePath $path
    Push-Location $fullPath

    $isDetached = git symbolic-ref -q HEAD
    if ($null -eq $isDetached) {
        Write-Host "Submodule $path is in a detached HEAD state. Skipping commit/push for this submodule."
    } else {
        git pull
        git add .

        $status = git status --porcelain
        if ($status) {
            git commit -m "$Message"
            git push
        } else {
            Write-Host "No changes to commit for submodule: $path"
        }
    }

    $nestedSubmodules = git submodule --quiet foreach 'echo $path'
    foreach ($nestedPath in $nestedSubmodules) {
        ProcessSubmodule $nestedPath $fullPath
    }

    Pop-Location
}

# Initialize and update submodules
git submodule update --init --recursive

# Get and process top-level submodules
$submodulePaths = git submodule --quiet foreach 'echo $path'
foreach ($path in $submodulePaths) {
    ProcessSubmodule $path (Get-Location)
}