Remove-Module ChocoStatDb -ErrorAction SilentlyContinue

. (Join-Path $PSScriptRoot "helpers.ps1")

$config = Get-PodeConfig
$env:ChocoStatDbFile = $config.Database

# There seems to be a bug in the https implementation
# PS 5.1 Clients can only connect once. All further requests will timeout.
# PS 7 Clients can interact normally through https.
Add-PodeEndpoint -Address * -Port $config.port -Protocol Http #s -SelfSigned

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

New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'AuthenticateSelf' -Sessionless -ScriptBlock {
    param($APIToken)

	Write-Host $WebEvent.Data.Secret
    $result = Test-ComputerSecret -ComputerID $WebEvent.Parameters['computerId'] -Secret $WebEvent.Data.Secret
    if ( $null -ne $result ) {
        return @{ User = $result }
    }


    return @{ Code = 403; Message = "Forbidden" }
}

Register-PodeEvent -Type Start -Name 'start' -ScriptBlock {

    Write-Host "Started ChocoStat-API-Server server on: $(Get-Date)"

    $computers = Get-ChocoStatComputer
    $computerPackages = Get-ChocoStatComputerPackage
    $packages = Get-ChocoStatPackage
    Write-Host "Currently hosting infos about $($computers.Count) computers with a total of $($computerPackages.Count) package installations and $($packages.Count) packages"
}

Use-PodeRoutes


New-PodeLoggingMethod -Terminal | Add-PodeLogger -Name "RequestsTerminal" -ScriptBlock { param($item) $item }
New-PodeLoggingMethod -File -Name $config.Logging.File.RequestLog | Add-PodeLogger -Name "RequestsFile" -ScriptBlock { param($item) $item }
New-PodeLoggingMethod -EventViewer -EventLogName $config.Logging.EventViewer.EventLogName -Source $config.Logging.EventViewer.RequestSource | Add-PodeLogger -Name "RequestsEventViewer" -ScriptBlock { param($item) $item }

New-PodeLoggingMethod -Terminal | Add-PodeLogger -Name "ErrorsTerminal" -ScriptBlock { param($item) $item }
New-PodeLoggingMethod -File -Name $config.Logging.File.ErrorLog | Add-PodeLogger -Name "ErrorsFile" -ScriptBlock { param($item) $item }
New-PodeLoggingMethod -EventViewer -EventLogName $config.Logging.EventViewer.EventLogName -Source $config.Logging.EventViewer.ErrorSource | Add-PodeLogger -Name "ErrorsEventViewer" -ScriptBlock { param($item) $item }


New-PodeLoggingMethod -Custom -ArgumentList $config -ScriptBlock {
    param($item, $config)

    if ($config.Logging.Terminal.Requests) {
        Write-PodeLog -Name "RequestsTerminal" -InputObject $item
    }
    if ($config.Logging.File.Requests) {
        Write-PodeLog -Name "RequestsFile" -InputObject $item
    }
    if ($config.Logging.EventViewer.Requests) {
        Write-PodeLog -Name "RequestsEventViewer" -InputObject $item
    }

} | Enable-PodeRequestLogging

New-PodeLoggingMethod -Custom -ArgumentList $config -ScriptBlock {
    param($item, $config)

    if ($config.Logging.Terminal.Requests) {
        Write-PodeLog -Name "ErrorsTerminal" -InputObject $item
    }
    if ($config.Logging.File.Requests) {
        Write-PodeLog -Name "ErrorsFile" -InputObject $item
    }
    if ($config.Logging.EventViewer.Requests) {
        Write-PodeLog -Name "ErrorsEventViewer" -InputObject $item
    }

} | Enable-PodeErrorLogging

