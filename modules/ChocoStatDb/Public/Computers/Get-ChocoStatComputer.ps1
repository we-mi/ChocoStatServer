function Get-ChocoStatComputer {
    <#
    .SYNOPSIS
        Lists computers in the database depending on the filters
    .DESCRIPTION
        The output can be filtered by one or more ComputerIDs _OR_ one or more ComputerNames which might contain SQL-Wildcards
    .EXAMPLE
        Get-ChocoStatComputer
        
        Lists all computers in the database
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5

        Lists only the computer with the ID "5"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerID 5,7

        Lists only the computers with the ID "5" and "7"
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org'

        Lists all computers which ends with .example.org
    .EXAMPLE
        Get-ChocoStatComputer -ComputerName '%.example.org','%foo%'

        Lists all computers which ends with ".example.org" or which contains the word foo
    #>
    
    [CmdletBinding(DefaultParameterSetName="ComputerName")]
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
        $ComputerName=@('%')
    )

    process {

        $Query = "SELECT * FROM Computers WHERE"
        if ($ComputerID) {
            $Query += ($ComputerID | ForEach-Object { " ComputerID=$_" } ) -join ' OR '
        } elseif ($ComputerName) {
            $Query += ($ComputerName | ForEach-Object { " ComputerName LIKE '$_'" } ) -join ' OR '
        }

        $Query += ";"

        Write-Verbose "Get-ChocoStatComputer: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerID = $ComputerID
            ComputerName = $ComputerName
        }
    }    
}
