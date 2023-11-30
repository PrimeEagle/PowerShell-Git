# PowerShell Script to Remove Ignored Files/Directories from GitHub Repository

# Define the path to the .gitignore file and the repository
$gitIgnorePath = "./.gitignore"

# Function to check if a path matches any .gitignore pattern
function Test-GitIgnoreMatch {
    param (
        [string]$path,
        [string[]]$patterns
    )

    foreach ($pattern in $patterns) {
        if ($path -like $pattern) {
            return $true
        }
    }
    return $false
}


# Read the .gitignore file
$gitIgnorePatterns = Get-Content $gitIgnorePath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith("#") }

# Convert directory patterns to PowerShell-compatible wildcard patterns
$gitIgnorePatterns = $gitIgnorePatterns -replace '/$', '/\*' -replace '^\[', '*['

# Get all files and directories in the repository
$allItems = Get-ChildItem -Recurse -Force | Select-Object -ExpandProperty FullName

# Remove base path to get relative paths
$repoBasePath = Resolve-Path .
$relativeItems = $allItems | ForEach-Object { $_.Substring($repoBasePath.Length + 1) }

# Check each item against the .gitignore patterns
$itemsToRemove = $relativeItems | Where-Object { Test-GitIgnoreMatch $_ $gitIgnorePatterns }

# Remove matched items from the repository
foreach ($item in $itemsToRemove) {
    git rm --cached $item -r
}

# Commit the changes
git commit -m "Remove ignored files/directories based on .gitignore"
