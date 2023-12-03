param(
    [string]$RepoUrl,
    [string]$SecretName,
    [string]$SecretValue
)

function Set-GithubSecret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )

    $ghCommand = "gh secret set $SecretName -b`"$SecretValue`" "
    Invoke-Expression $ghCommand
}

#$ownerRepo = $RepoUrl -replace "https://github.com/", ""
#$ownerRepo = $ownerRepo -replace "\.git$", ""

Set-GithubSecret -SecretName $SecretName -SecretValue $SecretValue