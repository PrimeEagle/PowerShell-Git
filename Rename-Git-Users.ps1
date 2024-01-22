<#
	.SYNOPSIS
	Renames users in the current git repository.
	
	.DESCRIPTION
	Renames users in the current git repository.

	.PARAMETER MappingFile
	Path of the mapping file to use. Mapping file should be formatter, one line per user, as "old email = new email, old username = new username".
	
	.INPUTS
	Path of the mapping file.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Rename-Git-Users.ps1 -MappingFile "usermap.txt"
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (	
		[Parameter(Mandatory = $true)]	[string]$MappingFile
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
		
		$emailMap = @{}
		$nameMap = @{}

		Get-Content $MappingFile | ForEach-Object {
			$parts = $_ -split ','
			$emailParts = $parts[0] -split '='
			$nameParts = $parts[1] -split '='

			$emailMap[$emailParts[0]] = $emailParts[1]
			$nameMap[$nameParts[0]] = $nameParts[1]
		}

		$emailMapJson = $emailMap | ConvertTo-Json
		$nameMapJson = $nameMap | ConvertTo-Json

		git filter-repo --force --email-callback "emailMap = $emailMapJson; return emailMap.get(original_email, original_email)" `
						--name-callback "nameMap = $nameMapJson; return nameMap.get(original_name, original_name)"
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