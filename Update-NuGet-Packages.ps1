# run the below line manually in PowerShell in order to store your token
# Get-Credential -UserName 'GitHub' -Message 'Enter your PAT' | Export-CliXml -Path "path\to\your\secure\file.xml"


# Define NuGet sources
$nugetSources = @("https://api.nuget.org/v3/index.json", "https://nuget.pkg.github.com/PrimeEagle/index.json")

# Retrieve the GitHub PAT from a secure location
$githubPat = Import-CliXml -Path "D:\My Code\PowerShell Scripts\secure.xml"

# Configure NuGet to authenticate with GitHub Packages
nuget sources Add -Name "GitHub" -Source "https://nuget.pkg.github.com/PrimeEagle/index.json" -Username PrimeEagle -Password $githubPat
nuget setapikey $githubPat -Source "githubpackages"


# Install NuGet CLI if not already installed
if (-not (Get-Command "nuget" -ErrorAction SilentlyContinue)) {
    Write-Host "NuGet CLI not found. Installing..."
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Package NuGet.CommandLine -Force -Scope CurrentUser
}

function Update-NuGetPackagesInCsproj {
    Param ([string]$csprojPath)

    Write-Host "Checking project $csprojPath"
    try {
        [xml]$csprojContent = Get-Content $csprojPath
    } catch {
        Write-Error "Error reading csproj file: $_"
        return
    }

    $packageReferences = $csprojContent.SelectNodes("//PackageReference")
    Write-Host "Found $($packageReferences.Count) package references in $csprojPath"

    foreach ($packageReference in $packageReferences) {
        $packageName = $packageReference.GetAttribute("Include")
        $currentVersion = $packageReference.GetAttribute("Version")
        $latestVersion = $null
        Write-Host "Checking package $packageName (current version: $currentVersion)"

        foreach ($source in $nugetSources) {
            try {
                $nugetSearchOutput = & nuget search "$packageName" -Source $source #-PreRelease
                if ($source -eq "https://api.nuget.org/v3/index.json") {
                    # Handling output format for NuGet official source
                    if ([string]$nugetSearchOutput -match [string]"\> $packageName\s+\|\s+(\S+)\s+\|") {
                        $latestVersion = $matches[1]
						Write-Host "-----latest version = $latestVersion"
                    }
                } elseif ($source -eq "https://nuget.pkg.github.com/PrimeEagle/index.json") {
                    # Handling output format for GitHub NuGet source
                    if ([string]$nugetSearchOutput -match [string]"\> $packageName\s+\|\s+(\S+)\s+\|") {
                        $latestVersion = $matches[1]
						Write-Host "-----latest version = $latestVersion"
                    }
                }
            } catch {
                Write-Warning "Error querying NuGet source $source for package ${packageName}: $_"
            }

            if ($latestVersion) {
                Write-Host "Found latest version $latestVersion for package $packageName in source $source"
                break
            }
        }

        if ($latestVersion -and ($latestVersion -ne $currentVersion)) {
            $packageReference.SetAttribute("Version", $latestVersion)
            Write-Host "Updated package $packageName from version $currentVersion to version $latestVersion"
        } elseif (-not $latestVersion) {
            Write-Warning "Latest version for package $packageName not found in any sources"
        } else {
            Write-Host "Package $packageName is already at the latest version $currentVersion"
        }
    }

    try {
        $csprojContent.Save($csprojPath)
        Write-Host "Saved updates to $csprojPath"
    } catch {
        Write-Error "Error saving updated csproj file: $_"
    }
}

# Update all submodules recursively
git submodule update --init --recursive

# Get a list of all submodules
$submodules = git config --file .gitmodules --get-regexp path | %{ $_.Split()[1] }

# Collect paths of all files in submodules
$submoduleFiles = @()
foreach ($submodule in $submodules) {
    $submoduleFiles += Get-ChildItem -Recurse -Path $submodule | Select-Object -ExpandProperty FullName
}

foreach ($submodule in $submodules) {
    # Change to the submodule directory
    Push-Location $submodule

    # Ensure on the correct branch and pull the latest changes
    git checkout main
    git stash
    git pull --rebase
    git stash pop

    # Update .csproj files in the submodule
    $csprojFiles = Get-ChildItem -Recurse -Filter *.csproj
    foreach ($file in $csprojFiles) {
        Update-NuGetPackagesInCsproj -csprojPath $file.FullName
        git add $file.FullName
    }

    # Commit and push changes in the submodule
    if (git commit -m "Update NuGet packages to latest versions in submodule") {
        git push origin main
    }

    # Return to the main repository directory
    Pop-Location
}

# Stash any unstaged changes in the main repository
git stash

# Ensure on the correct branch and pull the latest changes
git checkout main
git pull --rebase

# Apply the stash
git stash pop

# Update .csproj files in the main repository
$csprojFiles = Get-ChildItem -Recurse -Filter *.csproj -Exclude .git, .gitmodules
foreach ($file in $csprojFiles) {
    # Skip files that are part of any submodule
    if ($file.FullName -notin $submoduleFiles) {
        Update-NuGetPackagesInCsproj -csprojPath $file.FullName
        git add $file.FullName
    }
}

# Commit and push changes in the main repository
if (git commit -m "Update NuGet packages to latest versions") {
    git push origin main
}