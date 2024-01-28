<#
	.SYNOPSIS
	Add a repository secret to GitHub.
	
	.DESCRIPTION
	Add a repository secret to GitHub.

	.PARAMETER RepoUrl
	URL for the GitHub repository.
	
	.PARAMETER SecretName
	The name of the secret to store.
	
	.PARAMETER SecretValue
	The value of the secret to store.
	
	.INPUTS
	Repository URL, secret name, and secret value.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Add-Git-RepoSecret.ps1 -RepoUrl http://www.github.com/Repo7421 -SecretName Username -SecretValue User7421
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	
		[Parameter(Mandatory = $true]	[string]$RepoUrl,
		[Parameter(Mandatory = $true)]	[string]$SecretName,
		[Parameter(Mandatory = $true)]	[string]$SecretValue
	  )
DynamicParam { Build-BaseParameters }

Begin
{	
	Write-LogTrace "Execute: $(Get-RootScriptName)"
	$minParams = Get-MinimumRequiredParameterCount -CommandInfo (Get-Command $MyInvocation.MyCommand.Name)
	$cmd = @{}

	if(Get-BaseParamHelpFull) { $cmd.HelpFull = $true }
	if((Get-BaseParamHelpDetail) -Or ($PSBoundParameters.Count -lt $minParams)) { $cmd.HelpDetail = $true }
	if(Get-BaseParamHelpSynopsis) { $cmd.HelpSynopsis = $true }
	
	if($cmd.Count -gt 1) { Write-DisplayHelp -Name "$(Get-RootScriptPath)" -HelpDetail }
	if($cmd.Count -eq 1) { Write-DisplayHelp -Name "$(Get-RootScriptPath)" @cmd }
}
Process
{
	try
	{
		$isDebug = Assert-Debug

        function Set-GithubSecret {
            param(
                [string]$SecretName,
                [string]$SecretValue
            )

            $ghCommand = "gh secret set $SecretName -b`"$SecretValue`" "

            Invoke-Expression $ghCommand
        }

        if ($PSCmdlet.ShouldProcess($SecretName, 'Add to GitHub.')) 
        {
            Set-GithubSecret -SecretName $SecretName -SecretValue $SecretValue
        }
   	}
	catch [System.Exception]
	{
		Write-DisplayError $PSItem.ToString() -Exit
	}
}
End
{
	Write-DisplayHost "Done." -Style Done
}