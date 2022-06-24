function Remove-ChocoStatServerToken {
    <#
    .SYNOPSIS
        Removes a token for a user from the database
    .DESCRIPTION
        Removes a token for a user from the database. You will need the UserName, have a look at 'Get-ChocoStatServerToken'
    .NOTES
        This cmdlet does not check if the token exists beforehand.
    .EXAMPLE
        Remove-ChocoStatServerToken -UserName "demo"
        
        Removes the token for the user with the username "demo"
    .EXAMPLE
        Remove-ChocoStatServerToken -UserName "demo" -Confirm:$false
        
        Removes the token for the user with the username "demo" and skips the confirmation question
    #>
    
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # User for whom the token should be removed
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]        
        [String]
        $UserName,

        # Ask for confirmation
        [Parameter()]
        [Bool]
        $Confirm = $True,

        # Don't actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        $Query = "DELETE FROM Tokens WHERE UserName=@UserName;"
        Write-Verbose "Remove-ChocoStatServerToken: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would remove token for user '$UserName'"
        } else {
            $GoAhead = $False
            if ($Confirm) {
                $answer = Read-Host -Prompt "Remove token for user '$UserName' from database? (y/N)"
                if ($answer -eq "y") { $GoAhead = $True }
            } else { $GoAhead = $True }

            if ($GoAhead) {
                Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                    UserName = $UserName
                }
            } else {
                Write-Host -ForegroundColor Magenta "You chose not to remove the token for the user '$UserName'"
            }
        }        
    }    
}
