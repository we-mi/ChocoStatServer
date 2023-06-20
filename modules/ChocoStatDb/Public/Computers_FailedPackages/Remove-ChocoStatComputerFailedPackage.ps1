function Remove-ChocoStatComputerFailedPackage {
    <#
    .SYNOPSIS
        Removes a FailedPackage from a computer from the database
    .DESCRIPTION
        Removes a FailedPackage from a computer from the database. You will need the ComputerID, have a look at 'Get-ChocoStatComputer'. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .NOTES
        This cmdlet does not check if the FailedPackage was linked to the computer beforehand
    .EXAMPLE
        Remove-ChocoStatComputerFailedPackage -ComputerID 5 -PackageName "firefox"

        Removes firefox from computer with ID 5
    .EXAMPLE
        Remove-ChocoStatComputerFailedPackage -ComputerName "foo.example.org" -PackageName "firefox"

        Removes firefox from computer with name "foo.example.org"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "%.example.org" | Remove-ChocoStatComputerFailedPackage -PackageName "firefox"

        Removes firefox from all computers which names end with '.example.org'
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ComputerID to remove the FailedPackage from
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

        # FailedPackage to remove from computer
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String]
        $PackageName,

        [Parameter()]
        [Bool]
        $Confirm = $True,

        # Dont actually do anything
        [Parameter()]
        [Switch]
        $WhatIf
    )

    begin {
        $DbFile = Get-ChocoStatDBFile
    }

    process {

        $Query = "DELETE FROM Computers_FailedPackages WHERE PackageName=@PackageName"

        $QueryIDs = [array]($ComputerID | ForEach-Object { " ComputerID=$_" })

        if ($QueryIDs.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryIDs -join ' OR '
            $Query += " )"
        }

        $Query += ";"

        Write-Verbose "Remove-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

        if ($WhatIf.IsPresent) {
            Write-Host -ForegroundColor Magenta "WhatIf: Would remove FailedPackage '$PackageName' from computer with IDs '$($ComputerIDs -join ',')'"
        } else {
            $GoAhead = $False
            if ($Confirm) {
                $answer = Read-Host -Prompt "Remove FailedPackage '$PackageName' from computer with IDs '$($ComputerID -join ',')' from database? (y/N)"
                if ($answer -eq "y") { $GoAhead = $True }
            } else { $GoAhead = $True }

            if ($GoAhead) {
                Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                    PackageName = $PackageName
                }
            } else {
                Write-Host -ForegroundColor Magenta "You chose not to remove the FailedPackage from the computers"
            }
        }
    }
}
