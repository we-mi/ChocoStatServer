<#
    .SYNOPSIS
        List details for one computer
	.DESCRIPTION
		This function will return packages, sources and configs for one computer
	.EXAMPLE
        Get-ChocoStatComputer.ps1 -ComputerID 50 -RequestArgs "Before=2022-01-01"
	.NOTES
        This will return a json object
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [Alias("VarRouteValue")]
    [String]$ComputerID,

    [Parameter()]
    [String]$RequestArgs,

    [Parameter()]
    [String]$Body
)

$params = Convert-HTTPParamsToObject -GETParams $RequestArgs -POSTParams $Body

. (Join-Path $PSScriptRoot "..\Use-Environment.ps1")
Use-Environment -Config (Join-Path $PSScriptRoot "..\config.json")

# bouncer
if (-not (Test-ChocoStatServerToken -Token $params.Token -Type read) ) {
        return @{type = "error"; errormsg = "Not authenticated or not enough permissions" }
}

$computer = Get-ChocoStatComputer -ComputerName "foo.example.org" | Sort-Object -Property ComputerName

$packages = Get-ChocoStatComputerPackage -ComputerName "foo.example.org" | Select-Object -ExcludeProperty ComputerName

# TODO: Add sources and config

$computer | Add-Member -MemberType NoteProperty -Name "packages" -Value $packages


return $computer