<#
	.SYNOPSIS
	Remove items defined in .gitignore file from current git repository.
	
	.DESCRIPTION
	Remove items defined in .gitignore file from current git repository.

	.PARAMETER Message
	Commit message (default is "Remove ignored files/directories based on .gitignore").
	
	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Remove-Git-Ignored-Items.ps1
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	
		[Parameter]	[string]$Message = "Remove ignored files/directories based on .gitignore"
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
		
		$gitIgnorePath = "./.gitignore"

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

		$gitIgnorePatterns = Get-Content $gitIgnorePath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith("#") }
		$gitIgnorePatterns = $gitIgnorePatterns -replace '/$', '/\*' -replace '^\[', '*['
		$allItems = Get-ChildItem -Recurse -Force | Select-Object -ExpandProperty FullName

		$repoBasePath = Resolve-Path .
		$relativeItems = $allItems | ForEach-Object { $_.Substring($repoBasePath.Length + 1) }

		$itemsToRemove = $relativeItems | Where-Object { Test-GitIgnoreMatch $_ $gitIgnorePatterns }

		foreach ($item in $itemsToRemove) {
			git rm --cached $item -r
		}

		git commit -m $Message
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

