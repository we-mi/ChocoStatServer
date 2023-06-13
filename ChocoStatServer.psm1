function Start-ChocoStatServer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("https","http")]
        [String]$Protocol
    )


    Start-PodeServer {

        # makes reloading changes with CTRL+R possible
        . (Join-Path $PSScriptRoot "main.ps1")

    }
}
