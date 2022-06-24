function Remove-ChocoStatPackage {
    <#
    .SYNOPSIS
        Removes a Package from the database
    .DESCRIPTION
        Removes a Package from the database. You will need the PackageName, have a look at 'Get-ChocoStatPackage'. You can pipe the output from Get-ChocoStatPackage to this cmdlet.
    .NOTES
        This cmdlet does not check if the Package exists beforehand.
    .EXAMPLE
        Remove-ChocoStatPackage -PackageName "firefox"
        
        Removes the Package with the name "firefox"
    .EXAMPLE
        Get-ChocoStatPackage -PackageName '%' | Remove-ChocoStatPackage -Confirm:$false

        Removes all packages. Why would you do this?!?!
    #>
    
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]        
        [String[]]
        $PackageName,

        [Parameter()]
        [Bool]
        $Confirm = $True,

        [Parameter()]
        [Switch]
        $WhatIf
    )

    process {

        foreach ($singlePackage in $PackageName) {
            $Query = "DELETE FROM Packages WHERE PackageName=@singlePackage;"
            Write-Verbose "Remove-ChocoStatPackage: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove Package with Name '$singlePackage'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove Package with Name '$singlePackage' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                        singlePackage = $singlePackage
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the Package"
                }
            }
        }
    }    
}
