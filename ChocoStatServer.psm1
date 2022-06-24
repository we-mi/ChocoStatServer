Function Start-ChocoStatServer {
    <#
    .SYNOPSIS
        Starts the ChocoStatServer which handles REST-API-Requests
    .DESCRIPTION
        TODO
    .LINK
        TODO: Insert github link
    .EXAMPLE
        Start-ChocoStatServer
    #>
    
    [CmdletBinding()]
    param (
        # TCP-Port number on which the server will listen
        [Parameter()]
        [ValidateRange(1,65535)]
        [Int]$Port = 2306,

        # If you want the server to provide a secure connection you need a certificate and the thumbprint for it
        # The client needs a certificate as well, signed by the same CA (TODO: add more flexibility and use RestPS ACL functions)
        [Parameter()]
        [String]$SSLThumbprint,

        # Enforce the start if no Server certificate is used and the server will work in HTTP-Mode
        [Parameter()]
        [Switch]$Force
            
    )

    process {

        Remove-Module -Name RestPS -ErrorAction SilentlyContinue        
        Import-Module -Name (Join-Path $PSScriptRoot "modules\RestPS\RestPS.psd1") -ErrorAction Stop

        $RestSplat = @{
            RoutesFilePath = Join-Path $PSScriptRoot "api\endpoints\RestPSRoutes.json"
            RestPSLocalRoot = Join-Path $PSScriptRoot "api\bin"
            Port = $Port
        }

        if ( -not [String]::IsNullOrWhiteSpace($SSLThumbprint) ) { # HTTPS-Mode
            $RestSplat += @{
                SSLThumbprint = $SSLThumbprint
                VerificationType = "VerifyRootCA"
            }
        } else { # HTTP-Mode (needs the force parameter)
            if ( -not $Force.IsPresent) {
                Throw "Starting ChocoStatServer in HTTP-Mode needs the 'Force'-Parameter"
            }
        }

        Start-RestPSListener @RestSplat
    }        
}