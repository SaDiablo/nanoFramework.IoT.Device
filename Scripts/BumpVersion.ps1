<#
.SYNOPSIS
    Update the project version.
.DESCRIPTION
    Updates the nuget .nuspec file and all AssemblyInfo.cs files.
.PARAMETER SetVersion
    Set new version
.PARAMETER BumpMajor
    Bump major version, set minor and patch to zero
.PARAMETER BumpMinor
    Bump minor version, set patch to zero
.PARAMETER BumpPatch
    Bump patch version
.EXAMPLE
.NOTES
    Author: Andreas Gullberg Larsen
    Date:   Feb 8, 2014
	Based on original work by Luis Rocha from: http://www.luisrocha.net/2009/11/setting-assembly-version-with-windows.html
#>
[CmdletBinding()]
Param(  
    [Parameter(Mandatory=$true, Position=0, ParameterSetName="SetVersion", HelpMessage="Set version string")] [Alias("v")] [string]$setVersion,
    [Parameter(Mandatory=$true, Position=0, ParameterSetName="BumpMajor", HelpMessage="Bump major version number, set minor and patch to zero")] [Alias("m")] [switch]$bumpMajor,
	[Parameter(Mandatory=$true, Position=0, ParameterSetName="BumpMinor", HelpMessage="Bump minor version number, set patch to zero")] [Alias("i")] [switch]$bumpMinor,
	[Parameter(Mandatory=$true, Position=0, ParameterSetName="BumpPatch", HelpMessage="Bump patch version number")] [Alias("p")] [switch]$bumpPatch
)

#-------------------------------------------------------------------------------
# Displays how to use this script.
#-------------------------------------------------------------------------------
function Help {
	"Sets the AssemblyVersion and AssemblyFileVersion of AssemblyInfo.cs files`n"
	".\SetVersion.ps1 [VersionNumber]`n"
	"   [VersionNumber]     The version number to set, for example: 1.1.9301.0"
	"                       If not provided, a version number will be generated.`n"
}

#-------------------------------------------------------------------------------
# Description: Sets the AssemblyVersion and AssemblyFileVersion of 
#              AssemblyInfo.cs files.
#              Sets the <version></version> element of UnitsNet.nuspec file.
#
# Based on original work by Luis Rocha from: http://www.luisrocha.net/2009/11/setting-assembly-version-with-windows.html
#
# Author: Andreas Larsen
# Version: 1.1
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Update version numbers of AssemblyInfo.cs
#-------------------------------------------------------------------------------
function Update-AssemblyInfoFiles ([string] $version) {
    $assemblyVersionPattern = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $fileVersionPattern = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $assemblyVersion = 'AssemblyVersion("' + $version + '")';
    $fileVersion = 'AssemblyFileVersion("' + $version + '")';
    
    Get-ChildItem .\ -r | Where { $_.PSChildName -match "^AssemblyInfo\.cs$"} | ForEach-Object {
        $filename = $_.Directory.ToString() + '\' + $_.Name
        $filename + ' -> ' + $version
        
        # If you are using a source control that requires to check-out files before 
        # modifying them, make sure to check-out the file here.
        # For example, TFS will require the following command:
        # tf checkout $filename
    
        (Get-Content $filename -Encoding UTF8) | ForEach-Object {
            % {$_ -replace $assemblyVersionPattern, $assemblyVersion } |
            % {$_ -replace $fileVersionPattern, $fileVersion }
        } | Set-Content $filename -Encoding UTF8
    }    
}

#-------------------------------------------------------------------------------
# Update <releaseNotes> element in UnitsNet.nuspec
#-------------------------------------------------------------------------------
function Update-NuspecFileReleaseNotes ([string] $NuSpecFilePath, [xml] $nuspecXml, [string] $releaseInfo, [Version] $newVersion) {
	$updatedReleaseNotes = [string]::Format("v{0}.{1}.{2}: {3}`n`n{4}", $newVersion.Major, $newVersion.Minor, $newVersion.Build, $releaseInfo, $nuspecXml.package.metadata.releaseNotes)
	$nuspecXml.package.metadata.releaseNotes = $updatedReleaseNotes
	$nuspecXml.Save($NuSpecFilePath)    
}

function Update-NuspecVersion([string] $NuSpecFilePath, [xml] $nuspecXml, [Version] $newVersion) {
	$NuSpecFilePath + ' -> ' + $newVersion.ToString()
	$nuspecXml.package.metadata.version = $newVersion.ToString()
	$nuspecXml.Save($NuSpecFilePath)
}


function BumpMajor ([Version] $currentVersion) {
	return New-Object System.Version -ArgumentList ($currentVersion.Major+1), 0, 0
}

function BumpMinor([Version] $currentVersion) {
	return New-Object System.Version -ArgumentList $currentVersion.Major, ($currentVersion.Minor+1), 0
}

function BumpPatch([Version] $currentVersion) {    
	return New-Object System.Version -ArgumentList $currentVersion.Major, $currentVersion.Minor, ($currentVersion.Build+1);
}

#-------------------------------------------------------------------------------
# Parse arguments.
#-------------------------------------------------------------------------------
$NuSpecFilePath = "UnitsNet.nuspec"
[ xml ]$nuspecXml = Get-Content -Path $NuSpecFilePath

$currentVersion = [Version]::Parse($nuspecXml.package.metadata.version)

switch ($PsCmdlet.ParameterSetName) {
    "BumpMajor" {
		$newVersion = BumpMajor $currentVersion
    }
    "BumpMinor" {
		$newVersion = BumpMinor $currentVersion
    }
	"BumpPatch" {
		$newVersion = BumpPatch $currentVersion
    }
	"SetVersion" {
		$newVersion = [Version]::Parse($setVersion)
	}
}

"Bump version "+$currentVersion+" => "+$newVersion
$releaseNotes = Read-Host 'Enter release notes for .nuspec file'

Update-NuspecVersion $NuSpecFilePath $nuspecXml $newVersion
Update-NuspecFileReleaseNotes $NuSpecFilePath $nuspecXml $releaseNotes $newVersion
Update-AssemblyInfoFiles $newVersion