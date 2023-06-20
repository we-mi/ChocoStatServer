function Get-ChocoStatComputerFailedPackage {
    <#
    .SYNOPSIS
        Lists FailedPackages for one or more computers
    .DESCRIPTION
        Lists FailedPackages for one or more computers. You can filter by ComputerID or Computername and PackageName
    .EXAMPLE
        Get-ChocoStatComputerFailedPackage -PackageName "vlc" -ComputerName '%.example.org'

        Lists all computers whose names end with 'example.org' and have "vlc" installed
    #>

    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int[]]
        $ComputerID,

        # One or more PackageNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $PackageName,

        # One or more Versions to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript( { $_ -notmatch "[';`"``\/!§$%&()\[\]]" } ) ]
        [String[]]
        $Version
    )

    begin {
        $DbFile = Get-ChocoStatDBFile

        $Query = "SELECT Computers.ComputerName,Computers.ComputerID,PackageName,Version,Parameters,FailedOn FROM Computers_FailedPackages,Computers WHERE Computers_FailedPackages.ComputerID=Computers.ComputerID"
    }

    process {

        $QueryFilters = @()

        if ($ComputerID.Count -gt 0) {
            $QueryFilterComputer += $ComputerID | ForEach-Object { "Computers.ComputerID = $_" }
        }

        if ($PackageName) {
            $QueryFilterFailedPackage += $PackageName | ForEach-Object { "Computers_FailedPackages.PackageName LIKE '$_'" }
        }

        if ($Version) {
            $QueryFilterVersion += $Version | ForEach-Object { "Computers_FailedPackages.Version LIKE '$_'" }
        }

        if ($QueryFilterComputer.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterComputer -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterFailedPackage.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterFailedPackage -join ' OR '
            $Query += " ) "
        }

        if ($QueryFilterVersion.Count -gt 0) {
            $Query += " AND ("
            $Query += $QueryFilterVersion -join ' OR '
            $Query += " ) "
        }

        $Query += ";"

        Write-Verbose "Get-ChocoStatComputerFailedPackage: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $DbFile -SqlParameters @{
            ComputerName = $ComputerName
        }
    }

}
