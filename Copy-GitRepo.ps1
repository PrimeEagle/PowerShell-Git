param (
    [string]$sourceRepoUrl,
    [string]$targetRepoUrl,
    [string]$filePathToCopy = "",
    [string]$sourceBranch = "main",
    [string]$targetBranch = "main"
)

# Define a temporary directory for cloning
$tempDir = Join-Path -Path $Env:TEMP -ChildPath ("git-" + [Guid]::NewGuid().ToString())

# Clone the source repository
git clone -b $sourceBranch $sourceRepoUrl $tempDir
cd $tempDir

# Filter the repository
if ($filePathToCopy -ne "") {
    git filter-repo --path $filePathToCopy
} else {
    git filter-repo
}

# Add the target repository as a remote
git remote add target $targetRepoUrl

# Push the filtered history to the target repository
git push --force target HEAD:$targetBranch

# Clean up
cd ..
Remove-Item $tempDir -Recurse -Force

# Output
$copyPathMsg = if ($filePathToCopy -ne "") { "'$filePathToCopy' in " } else { "" }
Write-Host "Files $copyPathMsg from '$sourceRepoUrl' have been copied to '$targetRepoUrl' in branch '$targetBranch'."
