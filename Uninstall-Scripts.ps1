<#
	.SYNOPSIS
	Uninstalls prerequisites for scripts.
	
	.DESCRIPTION
	Uninstalls prerequisites for scripts.

	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Uninstall-Scripts
#>
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param ([Parameter()] [switch] $UpdateHelp,
	   [Parameter(Mandatory = $true)] [string] $ModulesPath)

Begin
{
	$script = $MyInvocation.MyCommand.Name
	if(-Not (Test-Path ".\$script"))
	{
		Write-Host "Installation must be run from the same directory as the installer script."
		exit
	}

	if(-Not (Test-Path $ModulesPath))
	{
		Write-Host "'$ModulesPath' was not found."
		exit
	}

	$Env:PSModulePath += ";$ModulesPath"
	
	if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -FilePath "pwsh.exe" -ArgumentList "-File `"$PSCommandPath`"", "-ModulesPath `"$ModulesPath`"" -Verb RunAs
		exit
	}
}

Process
{	
	Remove-PathFromProfile -PathVariable 'Path' -Path (Get-Location).Path
	
	Remove-AliasFromProfile -Script 'Get-GitHelp' -Alias 'ghelp'
	Remove-AliasFromProfile -Script 'Get-GitHelp' -Alias 'ggh'
	Remove-AliasFromProfile -Script 'Add-Git-RepoSecret' -Alias 'agrs'
	Remove-AliasFromProfile -Script 'Add-Git-RepoSecret' -Alias 'gars'
	Remove-AliasFromProfile -Script 'Commit-Git-Push-Submodules' -Alias 'cgps'
	Remove-AliasFromProfile -Script 'Commit-Git-Push-Submodules' -Alias 'gcps'
	Remove-AliasFromProfile -Script 'Copy-Git-Repo' -Alias 'cgr'
	Remove-AliasFromProfile -Script 'Copy-Git-Repo' -Alias 'gcr'
	Remove-AliasFromProfile -Script 'Get-Git-Users' -Alias 'ggu'
	Remove-AliasFromProfile -Script 'Remove-Git-File' -Alias 'rgf'
	Remove-AliasFromProfile -Script 'Remove-Git-File' -Alias 'grf'
	Remove-AliasFromProfile -Script 'Remove-Git-Ignored-Items' -Alias 'rgii'
	Remove-AliasFromProfile -Script 'Remove-Git-Ignored-Items' -Alias 'grii'
	Remove-AliasFromProfile -Script 'Remove-Git-LargeFile' -Alias 'rglf'
	Remove-AliasFromProfile -Script 'Remove-Git-LargeFile' -Alias 'grlf'
	Remove-AliasFromProfile -Script 'Rename-Git-Users' -Alias 'rgu'
	Remove-AliasFromProfile -Script 'Rename-Git-Users' -Alias 'gru'
	Remove-AliasFromProfile -Script 'Update-Git-All' -Alias 'uga'
	Remove-AliasFromProfile -Script 'Update-Git-All' -Alias 'gua'
	Remove-AliasFromProfile -Script 'Update-Git-NuGet-Packages' -Alias 'ugnp'
	Remove-AliasFromProfile -Script 'Update-Git-NuGet-Packages' -Alias 'gunp'
	Remove-AliasFromProfile -Script 'Update-Git-Submodules-To-Latest' -Alias 'ugsl'
	Remove-AliasFromProfile -Script 'Update-Git-Submodules-To-Latest' -Alias 'gusl'
	Remove-AliasFromProfile -Script 'Export-Git-Secret' -Alias 'egs'
	Remove-AliasFromProfile -Script 'Export-Git-Secret' -Alias 'ges'
}

End
{
	Format-Profile
	Complete-Install
}