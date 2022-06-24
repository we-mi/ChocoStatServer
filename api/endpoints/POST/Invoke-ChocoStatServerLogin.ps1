<#
    .DESCRIPTION
        This takes a username and a password and returns an API-Token which can be used in other functions to authenticate
    .EXAMPLE
        Invoke-ChocoStatServerLogin.ps1 -Body $Body
    .NOTES
    	The parameters 'username' and 'password' are mandatory parameters
#>

[CmdletBinding()]
param(
    [Parameter()]
    [String]
    $RequestArgs,

    [Parameter()]
    [String]
    $Body
)

$params = Convert-HTTPParamsToObject -GETParams $RequestArgs -POSTParams $Body

. (Join-Path $PSScriptRoot "..\Use-Environment.ps1")
Use-Environment -Config (Join-Path $PSScriptRoot "..\config.json")

$splat = @{
    Username    = $params.Username
    Type        = $null
    Duration    = 7200
}

$authenticated = $false

# just demo code...
if ($params.username -eq "demo_read" -and $params.password -eq "demo_read") {
    $splat.Type = "read"
    $authenticated = $true
} elseif ($params.username -eq "demo_write" -and $params.password -eq "demo_write") {
    $splat.Type = "write"
    $authenticated = $true
} elseif ($params.username -eq "demo_admin" -and $params.password -eq "demo_admin") {
    $splat.Type = "admin"
    $authenticated = $true
} else {
    $authenticated = $false
}

if ($authenticated) {
    # check if a token for the username already exists and delete it
    Get-ChocoStatServerToken -Username $params.Username | Remove-ChocoStatServerToken -Confirm:$False
    $message = New-ChocoStatServerToken @splat
} else {
    $message = "Login failed"
}

return $message