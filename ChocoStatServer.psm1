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

function Get-RandomPassword {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(8,256)]
        [Int]$Length = 8,

        [Parameter()]
        [Char[]]$Charset = ((97..122) + (65..90) + (48..57) + (33..47) | ForEach-Object { [char]$_ }),

        [Parameter()]
        [Int]$Count = 1
    )

    for ($i = 0; $i -lt $Count; $i++) {
        -Join($Charset | Get-Random -Count $Length)
    }
}
