<#
	.SYNOPSIS
	Installs prerequisites for scripts.
	
	.DESCRIPTION
	Installs prerequisites for scripts.

	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Install-Scripts
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
	Add-PathToProfile -PathVariable 'Path' -Path (Get-Location).Path
	Add-PathToProfile -PathVariable 'PSModulePath' -Path $ModulesPath
	
	Add-AliasToProfile -Script 'Get-GitHelp' -Alias 'ghelp'
	Add-AliasToProfile -Script 'Get-GitHelp' -Alias 'ggh'
	Add-AliasToProfile -Script 'Add-Git-RepoSecret' -Alias 'agrs'
	Add-AliasToProfile -Script 'Add-Git-RepoSecret' -Alias 'gars'
	Add-AliasToProfile -Script 'Commit-Git-Push-Submodules' -Alias 'cgps'
	Add-AliasToProfile -Script 'Commit-Git-Push-Submodules' -Alias 'gcps'
	Add-AliasToProfile -Script 'Copy-Git-Repo' -Alias 'cgr'
	Add-AliasToProfile -Script 'Copy-Git-Repo' -Alias 'gcr'
	Add-AliasToProfile -Script 'Get-Git-Users' -Alias 'ggu'
	Add-AliasToProfile -Script 'Remove-Git-File' -Alias 'rgf'
	Add-AliasToProfile -Script 'Remove-Git-File' -Alias 'grf'
	Add-AliasToProfile -Script 'Remove-Git-Ignored-Items' -Alias 'rgii'
	Add-AliasToProfile -Script 'Remove-Git-Ignored-Items' -Alias 'grii'
	Add-AliasToProfile -Script 'Remove-Git-LargeFile' -Alias 'rglf'
	Add-AliasToProfile -Script 'Remove-Git-LargeFile' -Alias 'grlf'
	Add-AliasToProfile -Script 'Rename-Git-Users' -Alias 'rgu'
	Add-AliasToProfile -Script 'Rename-Git-Users' -Alias 'gru'
	Add-AliasToProfile -Script 'Update-Git-All' -Alias 'uga'
	Add-AliasToProfile -Script 'Update-Git-All' -Alias 'gua'
	Add-AliasToProfile -Script 'Update-Git-NuGet-Packages' -Alias 'ugnp'
	Add-AliasToProfile -Script 'Update-Git-NuGet-Packages' -Alias 'gunp'
	Add-AliasToProfile -Script 'Update-Git-Submodules-To-Latest' -Alias 'ugsl'
	Add-AliasToProfile -Script 'Update-Git-Submodules-To-Latest' -Alias 'gusl'
	Add-AliasToProfile -Script 'Export-Git-Secret' -Alias 'egs'
	Add-AliasToProfile -Script 'Export-Git-Secret' -Alias 'ges'
}

End
{
	Format-Profile
	Complete-Install
}