function Remove-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Removes a package from a computer from the database
    .DESCRIPTION
        Removes a package from a computer from the database. You will need the ComputerID, have a look at 'Get-ChocoStatComputer'. You can pipe the output from Get-ChocoStatComputer to this cmdlet.
    .EXAMPLE
        Remove-ChocoStatComputerPackage -ComputerID 5 -PackageName "firefox"

        Removes firefox from computer with ID 5
    .EXAMPLE
        Remove-ChocoStatComputerPackage -ComputerName "foo.example.org" -PackageName "firefox"

        Removes firefox from computer with name "foo.example.org"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName "%.example.org" | Remove-ChocoStatComputerPackage -PackageName "firefox"

        Removes firefox from all computers which names end with '.example.org'
    #>

    [CmdletBinding()]
    [OutputType([Object])]

    param (
        # ComputerID to remove the package from
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [Int[]]
        $ComputerID,

        # Package to remove from computer
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

        $PackageObject = Get-ChocoStatPackage -PackageName $PackageName

        if ($null -ne $PackageObject) {

            $Query = "DELETE FROM Computers_Packages WHERE PackageID=@PackageID"

            $QueryIDs = [array]($ComputerID | ForEach-Object { " ComputerID=$_" })

            if ($QueryIDs.Count -gt 0) {
                $Query += " AND ("
                $Query += $QueryIDs -join ' OR '
                $Query += " )"
            }

            $Query += ";"

            Write-Verbose "Remove-ChocoStatComputerPackage: Execute SQL Query: $Query"

            if ($WhatIf.IsPresent) {
                Write-Host -ForegroundColor Magenta "WhatIf: Would remove package '$PackageName' from computer with IDs '$($ComputerIDs -join ',')'"
            } else {
                $GoAhead = $False
                if ($Confirm) {
                    $answer = Read-Host -Prompt "Remove package '$PackageName' from computer with IDs '$($ComputerID -join ',')' from database? (y/N)"
                    if ($answer -eq "y") { $GoAhead = $True }
                } else { $GoAhead = $True }

                if ($GoAhead) {
                    Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
                        PackageID = $PackageObject.PackageID
                    }
                } else {
                    Write-Host -ForegroundColor Magenta "You chose not to remove the package from the computers"
                }
            }

            # check if the package is installed anywhere
            if ( (Get-ChocoStatComputerPackage -PackageName $PackageName).Count -eq 0 ) {
                Remove-ChocoStatPackage -PackageID $PackageObject.PackageID -Confirm:$false
            }
        }
    }
}
