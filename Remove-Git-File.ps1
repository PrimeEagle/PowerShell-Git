<#
	.SYNOPSIS
	Remove a file from the current git repository.
	
	.DESCRIPTION
	Remove a file from the current git repository.

	.PARAMETER FileName
	The name of the file to remove.
	
	.INPUTS
	The name of the file to remove.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Remove-Git-File.ps1 -FileName "extra-file.txt"
#>

using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (	
		[Parameter(Mandatory = $true)]	[string]$FileName
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
		
		$gitLsFilesOutput = git ls-files $FileName
		if ($gitLsFilesOutput -ne $null) 
		{
			git reset HEAD -- $FileName
		}

		git rm --force --cached $FileName
		Remove-Item $FileName -ErrorAction SilentlyContinue
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