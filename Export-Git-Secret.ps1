<#
	.SYNOPSIS
	Exports a git secret to a local file.
	
	.DESCRIPTION
	Exports a git secret to a local file.

	.PARAMETER Name
	Username to use for the secret (default is "GitHub").
	
	.PARAMETER Secret
	The secret to save.
	
	.PARAMETER XmlFileName
	The name of the XML file where the secret should be saved.
	
	.INPUTS
	Name, secret, and XML filename.

	.OUTPUTS
	An XML file containing the secret.

	.EXAMPLE
	PS> .\Export-Git-Secret.ps1 -Secret "ACJ@L!#@" -XmlFileName "secret.xml"
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (	
		[Parameter]	[string]$Name,
		[Parameter(Mandatory = $true)]	[string]$Secret,
		[Parameter(Mandatory = $true)]	[string]$XmlFileName
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
		if(-Not $Name)
		{
			$userName = "GitHub"
		}
		else
		{
			$userName = $Name
		}
		
		Get-Credential -UserName $userName -Message $Secret | Export-CliXml -Path $XmlFileName
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