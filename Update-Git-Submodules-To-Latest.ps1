<#
	.SYNOPSIS
	Updates submodules to the latest version in the current git repository.
	
	.DESCRIPTION
	Updates submodules to the latest version in the current git repository.

	.PARAMETER Message
	Commit message.
	
	.INPUTS
	Commit message.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Update-Git-Submodules-To-Latest.ps1 -Message "Update submodules."
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	
		[Parameter(Mandatory=$true)] [string]$Message
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
		
		function UpdateSubmodule($path) {
			Write-Host "Updating submodule: $path"

			git -C $path fetch origin
			git -C $path reset --hard origin/main
			git -C $path clean -fd
			git -C $path submodule update --init --recursive
		}

		git pull origin main

		$submodules = git submodule foreach --quiet --recursive 'echo $path'
		foreach ($path in $submodules) {
			UpdateSubmodule $path
		}

		git add .
		git commit -m "$Message"
		git push origin main
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