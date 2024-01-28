<#
	.SYNOPSIS
	Commit and push all submodules in the current git repository.
	
	.DESCRIPTION
	Commit and push all submodules in the current git repository.

	.PARAMETER Message
	Commit message.
	
	.INPUTS
	Commit message.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Commit-Git-Push-Submodules.ps1 -Message "Update submodules."
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	
		[Parameter(Mandatory = $true)]	[string]$Message
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
		
		function ProcessSubmodule($path, $basePath) {
			Write-Host "Processing submodule: $path"

			$fullPath = Join-Path $basePath $path
			Push-Location $fullPath

			$isDetached = git symbolic-ref -q HEAD
			if ($null -eq $isDetached) 
            {
				Write-Host "Submodule $path is in a detached HEAD state. Skipping commit/push for this submodule."
			} 
            else 
            {
                if ($PSCmdlet.ShouldProcess("", 'Git pull and add.')) 
                {
				    git pull
				    git add .
                }

				$status = git status --porcelain
				if ($status) 
                {
                    if ($PSCmdlet.ShouldProcess($Message, 'Commit to git.')) 
                    {
					    git commit -m "$Message"
					    git push
                    }
				}
                else 
                {
					Write-Host "No changes to commit for submodule: $path"
				}
			}

			$nestedSubmodules = git submodule --quiet foreach 'echo $path'
			foreach ($nestedPath in $nestedSubmodules) {
				ProcessSubmodule $nestedPath $fullPath
			}

			Pop-Location
		}

        if ($PSCmdlet.ShouldProcess("", 'Update from git.')) 
        {
		    git submodule update --init --recursive
        }
		$submodulePaths = git submodule --quiet foreach 'echo $path'

		foreach ($path in $submodulePaths) {
			ProcessSubmodule $path (Get-Location)
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