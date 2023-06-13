Remove-Module ChocoStatDb -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot "helpers.ps1")

$config = Get-PodeConfig
$env:ChocoStatDbFile = $config.Database

Add-PodeEndpoint -Address * -Port $config.port -Protocol Https -SelfSigned

#Enable-PodeSessionMiddleware -Duration 120 -Extend -UseHeaders

New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'AuthenticateRead' -Sessionless -ScriptBlock {
    param($APIToken)

    $APITokenObject = Get-ChocoStatAPIToken -APIToken $APIToken

    if ($APITokenObject) {
        if ($APITokenObject.Type -match "read|write|admin") {
            return @{ User = $ApiTokenObject.UserName }
        }
    }

    return @{ Code = 403; Message = "Forbidden" }
}

New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'AuthenticateWrite' -Sessionless -ScriptBlock {
    param($APIToken)

    $APITokenObject = Get-ChocoStatAPIToken -APIToken $APIToken

    if ($APITokenObject) {
        if ($APITokenObject.Type -match "write|admin") {
            return @{ User = $ApiTokenObject.UserName }
        }
    }

    return @{ Code = 403; Message = "Forbidden" }
}

New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'AuthenticateAdmin' -Sessionless -ScriptBlock {
    param($APIToken)

    $APITokenObject = Get-ChocoStatAPIToken -APIToken $APIToken

    if ($APITokenObject) {
        if ($APITokenObject.Type -match "admin") {
            return @{ User = $ApiTokenObject.UserName }
        }
    }

    return @{ Code = 403; Message = "Forbidden" }
}

New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'AuthenticateAdminOrSelf' -Sessionless -ScriptBlock {
    param($APIToken)

    $APITokenObject = Get-ChocoStatAPIToken -APIToken $APIToken

    if ($null -ne $APITokenObject) {
        if ($APITokenObject.Type -match "admin") {
            return @{ User = $ApiTokenObject.UserName }
        }
    }

    $result = Test-ComputerSecret -ComputerID $WebEvent.Parameters['computerId'] -Secret $WebEvent.Data.Secret
    if ( $null -ne $result ) {
        return @{ User = $result }
    }


    return @{ Code = 403; Message = "Forbidden" }
}

Register-PodeEvent -Type Start -Name 'start' -ScriptBlock {

    Write-Host "Started ChocoStat-API-Server server on: $(Get-Date)"

    $computers = Get-ChocoStatComputer -Packages
    $totalPackages = $computers.Packages.Count
    $uniquePackages = ($computers.Packages | Sort-Object -Property PackageName -Unique).Count
    Write-Host "Currently hosting infos about $($computers.Count) computers with a total of $($totalPackages) package installations and $($uniquePackages) packages"
}

Use-PodeRoutes

New-PodeLoggingMethod -Terminal | Enable-PodeRequestLogging

#New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Error, Warning, Informational, Verbose, Debug
