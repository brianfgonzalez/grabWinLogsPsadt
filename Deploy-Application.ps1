<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = 'grabLogs'
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '12/29/2020'
	[string]$appScriptAuthor = 'Brian Gonzalez'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.3'
	[string]$deployAppScriptDate = '30/09/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		#Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>


		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>
		#region FUNCTIONS
		function Get-RegistryInfo {
			param (
				[Parameter(Mandatory=$true)]
				[string]$Key,
				[Parameter(Mandatory=$false)]
				[string]$Value,
				[Parameter(Mandatory=$false)]
				[bool]$Recurse = $true,
				[Parameter(Mandatory=$true)]
				[string]$Outfile
			)
		
		
			$result = @()
			If (! (Test-Path ($Key)) ) 
			{
				('key "{0}" doesnt exist or is inaccessible under this user context' -f $Key) | Out-File $Outfile -Force 
			} elseIf ($Value) {
				Write-Host ('Value check is triggered for: {0}\{1}' -f $Key, $Value)
				try
				{
					Get-ItemProperty -Path $Key | Select-Object -ExpandProperty $Value -ErrorAction SilentlyContinue | Out-Null
				} catch {
					('value "{0}" doesnt exist or is inaccessible under this user context' -f $Value) | Out-File $Outfile -Force
				}
				$result += Get-ItemProperty -Path ('{0}' -f $Key) -Name $Value
			} elseif ($Recurse) {
				Write-Host ('Recursive scan triggered: {0}\*' -f $Key)
				$result += Get-ItemProperty -Path ('{0}\*' -f $Key)
				$result += Get-ItemProperty -Path ('{0}' -f $Key)
			} else {
				Write-Host ('Standard scan triggered: {0}' -f $Key)
				$result += Get-ItemProperty -Path ('{0}' -f $Key)
			}
			if ($result)
			{
				$result | `
					ForEach-Object {
						$keyPathValue = ($_.PSPath -replace ([Regex]::Escape('Microsoft.PowerShell.Core\Registry::')),'')
						$_ | Add-Member -NotePropertyName 'KeyPath' -NotePropertyValue $keyPathValue -PassThru
					} | `
					Select-Object * -exclude PSPath, PSParentPath, PSChildName, PSProvider, PSDrive | `
					Sort-Object -Property KeyPath | `
					Format-List -GroupBy KeyPath | `
					Out-String -Width 10000 | `
					Out-File $Outfile -Force
			} else {
				Write-Host 'No results found'
				'no results were found' | Out-File $Outfile -Force
			}
		}
		
		function Get-FolderContentInfo {
			param (
				[Parameter(Mandatory=$true)]
				[string]$Path,
				[Parameter(Mandatory=$false)]
				[string]$Filter = "",
				[Parameter(Mandatory=$false)]
				[bool]$Recurse = $true,
				[Parameter(Mandatory=$true)]
				[string]$Outfile
			)
		
			If (! (Test-Path ($Path)) ) 
			{
				('Path "{0}" doesnt exist or is inaccessible under this user context' -f $Path) | Tee-Object $Outfile
			} elseif ($Recurse) {
				$result = Get-ChildItem -Path $Path -Filter $Filter -Recurse -File -ErrorAction SilentlyContinue
			} else {
				$result = Get-ChildItem -Path $Path -Filter $Filter -File -ErrorAction SilentlyContinue
			}
			if ($result)
			{
				$result | `
					ForEach-Object {
						$_ | Add-Member Noteproperty FileVersion $_.VersionInfo.FileVersion
						$_ | Add-Member NoteProperty KbSize ([math]::ceiling($_.Length / 1kb))
					}
				$result | Format-Table -AutoSize `
						-Property @{e='FullName'; label='FullPath'},
							@{e='Name'; label='FileName'},
							@{e='LastWriteTime'; label='Date'},
							@{e='FileVersion'; label='Version'},
							@{e='kbSize'; label='Size(kb)'} | `
							Out-String -Width 10000 | `
							Out-File $Outfile -Force
			} else {
				('"{0}" with "{1}" filter: No result found' -f $Path, $Filter) | Tee-Object $Outfile
			}
			
		}
		
		function Start-Robocopy {
			param (
				[Parameter(Mandatory=$true)]
				[string]$SourceFolder,
				[Parameter(Mandatory=$true)]
				[string]$Destination,
				[Parameter(Mandatory=$true)]
				[string]$Filter,
				[Parameter(Mandatory=$false)]
				[bool]$Recurse = $true,
				[Parameter(Mandatory=$true)]
				[string]$Log
			)
		
			$rcPath = ('{0}\System32\Robocopy.exe' -f $env:windir)
			$rcArgs = ('"{0}" "{1}" "{2}"' -f $SourceFolder, $Destination, $Filter )
			if ($Recurse) { $rcArgs += " /S" }
			Write-Host ('Executing: {0} {1}...' -f $rcPath, $rcArgs)
			Write-Host ('Log file: {0}' -f $Log)
			Start-Process -FilePath $rcPath -ArgumentList $rcArgs -Wait -NoNewWindow -RedirectStandardOutput $Log
		}
		#endregion

		#region VARIABLES
		[xml] $config = Get-Content "$PSScriptRoot\config.xml"
		$tempFolderName = ('grabLogs_{0}' -f (Get-Date -format "yyyyMMddhhmm") )
		$tempFolder = ('{0}\{1}' -f $env:TEMP, $tempFolderName)
		$remoteShare = "\\<SERVER>\<SHARE>"
		$fileCopyUser = '<DOMAIN>\<USER>'
		$timeStamp = (Get-Date -format "hhmm")
		#endregion
		New-Item $tempFolder -ItemType Directory -Force
		
		#region SCRIPTS
		foreach ( $script in $config.main.scripts.script )
		{
			if ($script.enabled -eq $true)
			{
				Show-InstallationProgress -StatusMessage ('{0}: Executing: {1}' -f $timeStamp, $script.name.ToUpper())
				if ($script.type -eq "winbatch")
				{
					$script.'#cdata-section'.Trim() | Out-File $env:TEMP\tmp.bat -Encoding ascii
					cmd.exe /c $env:TEMP\tmp.bat > $tempFolder\$($script.name).txt
				}
				if ($script.type -eq "powershell")
				{
					$script.'#cdata-section'.Trim() | Out-File $env:TEMP\tmp.ps1 -Encoding ascii
					cmd.exe /c powershell -executionpolicy bypass -file  $env:TEMP\tmp.ps1 > $tempFolder\$($script.name).txt
				}
				if ($script.extra_file)
				{
					$extraFilePath = $ExecutionContext.InvokeCommand.ExpandString( $script.extra_file )
					Copy-Item `
						-Path $extraFilePath `
						-Destination $tempFolder -Verbose
				}
			}
		}
		#endregion

		#region REGISTRY
		foreach ( $registry in $config.main.registry.key )
		{
			if ($registry.enabled -eq $true)
			{
				Show-InstallationProgress -StatusMessage ('{0}: Scanning: {1}' -f $timeStamp, $registry.InnerText)
				Get-RegistryInfo `
					-Key $registry.InnerText `
					-Outfile ( '{0}\{1}.txt' -f $tempFolder, $($registry.name) ) `
					-Recurse ( $($registry.recurse) -eq $true )
			}
		}
		
		foreach ( $registry in $config.main.registry.value )
		{
			if ( $registry.enabled -eq $true )
			{
				Show-InstallationProgress -StatusMessage ('{0}: Scanning: {1}' -f $timeStamp, $registry.InnerText)
				Get-RegistryInfo `
					-Key $registry.InnerText `
					-Outfile ( '{0}\{1}.txt' -f $tempFolder, $($registry.name) ) `
					-Recurse ( $($registry.recurse) -eq $true ) `
					-Value $registry.value
			}
		}
		#endregion

		#region FILESYSTEM
		foreach ( $folder in $config.main.filesystem.folder )
		{
				if ($folder.enabled -eq $true)
				{
					$folderPath = $ExecutionContext.InvokeCommand.ExpandString( $folder.innerText )
					if ( Test-Path $folderPath )
					{
						Show-InstallationProgress -StatusMessage ('{0}: Listing: "{1}" with Filter: "{2}"' -f $timeStamp, $folderPath.ToUpper(), $folder.filter.ToUpper())
						New-Item ('{0}\{1}' -f $tempFolder,$folder.name) -ItemType Directory -Force
		
						Get-FolderContentInfo -Path $folderPath `
							-Outfile ('{0}\{1}\{1}_LIST.txt' -f $tempFolder,$folder.name) `
							-Filter $folder.filter -Recurse ( $($folder.recurse) -eq $true ) `
						
						if ($folder.copy -eq $true) {
							Show-InstallationProgress -StatusMessage ('{0}: Copying: "{1}" with Filter "{2}"' -f $timeStamp, $folderPath.ToUpper(), $folder.filter.ToUpper())
							Start-Robocopy `
								-SourceFolder $folderPath `
								-Filter $folder.filter `
								-Destination ('{0}\{1}' -f $tempFolder, $folder.name) `
								-Log ('{0}\{1}\{1}_COPYLOG.txt' -f $tempFolder,$folder.name)
						}
					} else {
						Write-Host ('{0}: "{1}" Test-Path failed...' -f $timeStamp, $folderPath.ToUpper())
					}
				}
		}
		#endregion
		
		#region ZIPFILE
		$src = $tempFolder
		$zip = ('{0}\{1}.zip' -f $env:SystemDrive, $tempFolderName)
		Show-InstallationProgress -StatusMessage ('{0}: Compressing: {1}' -f $timeStamp, $zip.ToUpper())
		[void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
		[IO.Compression.ZipFile]::CreateFromDirectory($src, $zip, 'Optimal', $false)
		#endregion

		#region COPYZIP
		$plaintext_password_file = "$PSScriptRoot\plaintext.txt" # Stores the password in plain text - only used once, then deleted
		$encryted_password_file = "$PSScriptRoot\copy_pass.txt"  # Stores the password in "safe" encrypted form - used for subsequent runs of the script
																 #   - can only be decrypted by the windows user that wrote it
		$file_copy_user = $fileCopyUser

		# Check to see if there is a new plaintext password
		if (Test-Path $plaintext_password_file)
		{
			# Read in plaintext password, convert to a secure-string, convert to an encrypted-string, and write out, for use later
			get-content $plaintext_password_file | `
				convertto-securestring -asplaintext -force | `
				convertfrom-securestring | out-file $encryted_password_file
			# Now we have encrypted password, remove plain text for safety
			Remove-Item $plaintext_password_file
		}


		# Read in the encrypted password, convert to a secure-string
		$pass = get-content $encryted_password_file | convertto-securestring

		# create a credential object for the other user, using username and password stored in secure-string
		$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $file_copy_user,$pass

		# Connect to network file location as the other user and map to drive J:
		New-PSDrive -Name J -PSProvider FileSystem -Root $remoteShare -Credential $credentials
		New-Item "J:\$env:COMPUTERNAME\" -ItemType Directory -Force
		Copy-Item -Force -Verbose -Path $zip -Destination "J:\$env:COMPUTERNAME\"
		Remove-PSDrive -Name J -Force
		
		#region CLEANUP
		Show-InstallationProgress -StatusMessage ('{0}: Cleaning Up: {1}' -f $timeStamp, $src)
		Remove-Item -Path $tempFolder -Force -Recurse
		#endregion


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

		## Display a message at the end of the install
		# If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>


		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>


		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>


	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>


    }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
