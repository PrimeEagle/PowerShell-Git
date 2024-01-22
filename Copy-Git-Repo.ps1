<#
	.SYNOPSIS
	Makes a copy of a git repository.
	
	.DESCRIPTION
	Makes a copy of a git repository.

	.PARAMETER SourceRepoUrl
	The URL of the source repository to copy.
	
	.PARAMETER TargetRepoUrl
	The URL of the destination repository to create.
	
	.PARAMETER FilePathToCopy
	The path to copy in the source repository.
	
	.PARAMETER sourceBranch
	Name of the source branch (default = "main").
	
	.PARAMETER TargetRepoUrl
	Name of the target branch (default = "main").
	
	.INPUTS
	Source URL, target URL, path to copy, source branch, target branch.

	.OUTPUTS
	The new repository.

	.EXAMPLE
	PS> .\Copy-Git-Repo.ps1 -SourceRepoUrl "http://sourcegit.com" -TargetRepoUrl "http://targetgit.com" -FilePathToCopy "/src"
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param (	
		[Parameter(Mandatory = $true)]	[string]$SourceRepoUrl,
		[Parameter(Mandatory = $true)]	[string]$TargetRepoUrl,
		[Parameter(Mandatory = $true)]	[string]$FilePathToCopy = "",
		[Parameter(Mandatory = $true)]	[string]$SourceBranch = "main",
		[Parameter(Mandatory = $true)]	[string]$TargetBranch = "main"
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
		
		$tempDir = Join-Path -Path $Env:TEMP -ChildPath ("git-" + [Guid]::NewGuid().ToString())
		git clone -b $SourceBranch $SourceRepoUrl $tempDir
		cd $tempDir

		if ($FilePathToCopy -ne "") {
			git filter-repo --path $FilePathToCopy
		} else {
			git filter-repo
		}

		git remote add target $TargetRepoUrl
		git push --force target HEAD:$TargetBranch

		cd ..
		Remove-Item $tempDir -Recurse -Force

		$copyPathMsg = if ($FilePathToCopy -ne "") { "'$FilePathToCopy' in " } else { "" }
		Write-Host "Files $copyPathMsg from '$SourceRepoUrl' have been copied to '$TargetRepoUrl' in branch '$TargetBranch'."
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
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------