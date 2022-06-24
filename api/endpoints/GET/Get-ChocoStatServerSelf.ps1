<#
    .SYNOPSIS
        Returns the own user object if authenticated
	.DESCRIPTION
		Returns the own user object if authenticated
	.EXAMPLE
        Get-ChocoStatServerSelf.ps1 -RequestArgs "TOKEN=2caa4472495a4610ab1ac17d2cbd5722c6bd07e951cd4f1eab4c8668e0eb83b0"
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

$self = Get-ChocoStatServerToken | Where-Object { $_.Token -eq $params.Token }

if ($null -ne $self) {
    $self | Add-Member -MemberType NoteProperty -Name "Expires" -Value ($self.WhenCreated + $self.Duration)
    $self | Add-Member -MemberType NoteProperty -Name "WhenCreatedReadable" -Value ([datetimeoffset] '1970-01-01Z').AddSeconds($self.WhenCreated).LocalDateTime
    $self | Add-Member -MemberType NoteProperty -Name "ExpiresReadable" -Value ([datetimeoffset] '1970-01-01Z').AddSeconds($self.WhenCreated + $self.Duration).LocalDateTime
    if (Test-ChocoStatServerToken -Token $self.Token -Type $self.Type) {
        $self | Add-Member -MemberType NoteProperty -Name "status" -Value "valid"
        @{ type = "success"; data = $self }
    } else {
        $self | Add-Member -MemberType NoteProperty -Name "status" -Value "expired"
        @{ type = "error"; errormsg = "Token expired, please re-login"; data = $self }
    }
} else {
    @{ type = "error"; errormsg = "Token not found, user might not be logged in" }
}