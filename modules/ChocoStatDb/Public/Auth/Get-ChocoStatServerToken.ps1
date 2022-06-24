function Get-ChocoStatServerToken {
    <#
    .SYNOPSIS
        Lists all API Tokens
    .DESCRIPTION
        Lists all API Tokens
    .EXAMPLE
        Get-ChocoStatServerToken

        Lists all tokens
    .EXAMPLE
        Get-ChocoStatServerToken -Token "<token>"

        Lists details for the given token
    #>
    
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # The desired token to list. Can contain wildcards
        [Parameter()]
        [String]
        $Token = '%'
    )

    process {
        
        $Query = "SELECT * FROM Tokens WHERE Token LIKE @Token;"

        Write-Verbose "Get-ChocoStatServerToken: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            Token    = $Token
        }
    }    
}
