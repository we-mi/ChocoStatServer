function Get-ChocoStatComputerPackage {
    <#
    .SYNOPSIS
        Lists packages for one or more computers
    .DESCRIPTION
        Lists packages for one or more computers. You can filter by ComputerID or Computername and PackageName
    .EXAMPLE
        Get-ChocoStatComputerPackage -PackageName "vlc" -ComputerName '%.example.org'

        Lists all computers whose names end with 'example.org' and have "vlc" installed
    #>

    [CmdletBinding(DefaultParameterSetName = "ComputerName")]
    [OutputType([Object[]])]

    param (
        # One or more ComputerIDs to search for
        [Parameter(
            ParameterSetName = "ComputerID",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [Int[]]
        $ComputerID,

        # One or more ComputerNames to search for (can contain SQL wildcards)
        [Parameter(
            ParameterSetName = "ComputerName",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [String[]]
        $ComputerName=@('%'),

        # One or more PackageNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1
        )]
        [String[]]
        $PackageName=@('%')
    )

    process {
        $Query = "SELECT Computers.ComputerName,Computers.ComputerID,PackageName,Version,Parameters,InstalledOn FROM Computers_Packages,Computers WHERE Computers_Packages.ComputerID=Computers.ComputerID"

        if ($PSCmdlet.ParameterSetName -eq "ComputerName") {
            $Query += " AND ("
            $Query += ($ComputerName | ForEach-Object { " Computers.ComputerName LIKE '$_'" } ) -join ' OR '
            $Query += " )"
        } else {
            $Query += " AND ("
            $Query += ($ComputerID | ForEach-Object { " Computers.ComputerID=$_" } ) -join ' OR '
            $Query += " )"
        }

        if ($PackageName) {
            $Query += " AND ("
            $Query += ($PackageName | ForEach-Object { " Computers_Packages.PackageName LIKE '$_'" } ) -join ' OR '
            $Query += " )"
        }

        $Query += ";"

        Write-Verbose "Get-ChocoStatComputerPackage: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
        }
    }
    
}