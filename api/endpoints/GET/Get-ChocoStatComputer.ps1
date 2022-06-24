<#
    .SYNOPSIS
        List one or more computers
	.DESCRIPTION
		This function will return one or more computer objects from the database, depending on the given filter parameters
	.EXAMPLE
        Get-ChocoStatComputer.ps1 -RequestArgs "ID=30&Before=2022-01-01"
	.NOTES
        This will return a json object
#>
[CmdletBinding()]
param(
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

if ($params.ComputerName) {
    $computers = Get-ChocoStatComputer | Where-Object { $_.ComputerName -like $params.ComputerName } | Sort-Object -Property ComputerName
} else {
    $computers = Get-ChocoStatComputer | Sort-Object -Property ComputerName
}

if ($params.After -and [datetime]$params.After) {
    $computers = $computers | Where-Object { $_.LastContact -gt [datetime]$params.After }
}

if ($params.Before -and [datetime]$params.Before) {
    $computers = $computers | Where-Object { $_.LastContact -lt [datetime]$params.Before }
}

if ($params.Limit) {
    $computers = $computers | Select-Object -First $params.Limit
}

return $computers