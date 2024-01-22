<#
	.SYNOPSIS
	Update NuGet packages in current git repository and all submodules.
	
	.DESCRIPTION
	Update NuGet packages in current git repository and all submodules.

	.PARAMETER NuGetSourceUrl
	URL for the default NuGet package source.
	
	.PARAMETER GitHubSourceUrl
	URL for the GitHub NuGet package source.
	
	.PARAMETER GitHubSourceName
	The source name defined on the local system for the GitHub package service.

	.PARAMETER GitHubUsername
	Username for the GitHub repository.
	
	.PARAMETER PatFileName
	Path to XML file containing the PAT for the GitHub repository.
	
	.PARAMETER Message
	Commit message.
	
	.INPUTS
	Source URL for package server, optional source name and PAT file name.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Update-Git-NuGet-Packages.ps1 -NuGetSourceUrl "https://api.nuget.org/v3/index.json" -GitHubSourceUrl "https://nuget.pkg.github.com/PrimeEagle/index.json" -GitHubSourceName "githubpackages" -PatFileName "secure.xml"
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	
		[Parameter(Mandatory = $true, ParameterSetName = "nuget")]	[string]$NuGetSourceUrl,
		[Parameter(Mandatory = $true, ParameterSetName = "github")]	[string]$GitHubSourceUrl,
		[Parameter(Mandatory = $true, ParameterSetName = "github")]	[string]$GitHubSourceName,
		[Parameter(Mandatory = $true, ParameterSetName = "github")]	[string]$GitHubUsername,
		[Parameter(Mandatory = $true, ParameterSetName = "github")]	[string]$PatFileName,
		[Parameter(ParameterSetName = "nuget"]
		[Parameter(ParameterSetName = "github"]						[string]$Message = "Update NuGet packages to latest versions"
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
		
		if (-not (Get-Command "nuget" -ErrorAction SilentlyContinue)) {
			Write-Host "NuGet CLI not found. Installing..."
			Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
			Install-Package NuGet.CommandLine -Force -Scope CurrentUser
		}
		
		$githubPat = Import-CliXml -Path $PatFileName
		nuget sources Add -Name "GitHub" -Source $GitHubSourceUrl -Username $GitHubUsername -Password $githubPat
		nuget setapikey $githubPat -Source $GitHubSourceName

		function Update-NuGetPackagesInCsproj {
			Param ([string]$csProjPath)

			try {
				[xml]$csprojContent = Get-Content $csProjPath
			} catch {
				Write-Error "Error reading csproj file: $_"
				return
			}

			$packageReferences = $csprojContent.SelectNodes("//PackageReference")

			foreach ($packageReference in $packageReferences) {
				$packageName = $packageReference.GetAttribute("Include")
				$currentVersion = $packageReference.GetAttribute("Version")
				$latestVersion = $null
				Write-Host "Checking package $packageName (current version: $currentVersion)"

				$nugetSearchOutput = & nuget search "$packageName" -Source $source #-PreRelease
				if ($NuGetSourceUrl) {
					if ([string]$nugetSearchOutput -match [string]"\> $packageName\s+\|\s+(\S+)\s+\|") {
						$latestVersion = $matches[1]
					}
				} elseif ($GitHubSourceUrl) {
					if ([string]$nugetSearchOutput -match [string]"\> $packageName\s+\|\s+(\S+)\s+\|") {
						$latestVersion = $matches[1]
					}
				}

				if ($latestVersion) {
					Write-Host "Found latest version $latestVersion for package $packageName in source $source"
					break
				}

				if ($latestVersion -and ($latestVersion -ne $currentVersion)) {
					$packageReference.SetAttribute("Version", $latestVersion)
					Write-Host "Updated package $packageName from version $currentVersion to version $latestVersion"
				} elseif (-not $latestVersion) {
					Write-Warning "Latest version for package $packageName not found in any sources"
				} else {
					Write-Host "Package $packageName is already at the latest version $currentVersion"
				}
			}

			try {
				$csprojContent.Save($csProjPath)
			} catch {
				Write-Error "Error saving updated csproj file: $_"
			}
		}

		git submodule update --init --recursive

		$submodules = git config --file .gitmodules --get-regexp path | %{ $_.Split()[1] }
		$submoduleFiles = @()
		foreach ($submodule in $submodules) {
			$submoduleFiles += Get-ChildItem -Recurse -Path $submodule | Select-Object -ExpandProperty FullName
		}

		foreach ($submodule in $submodules) {
			Push-Location $submodule

			git checkout main
			git stash
			git pull --rebase
			git stash pop

			$csProjPath = Get-ChildItem -Recurse -Filter *.csproj
			foreach ($file in $csProjPath) {
				Update-NuGetPackagesInCsproj -csprojPath $file.FullName
				git add $file.FullName
			}

			if (git commit -m $Message) {
				git push origin main
			}

			Pop-Location
		}

		git stash
		git checkout main
		git pull --rebase
		git stash pop

		$csprojFiles = Get-ChildItem -Recurse -Filter *.csproj -Exclude .git, .gitmodules
		foreach ($file in $csprojFiles) {
			if ($file.FullName -notin $submoduleFiles) {
				Update-NuGetPackagesInCsproj -csprojPath $file.FullName
				git add $file.FullName
			}
		}

		if (git commit -m $Message) {
			git push origin main
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
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------