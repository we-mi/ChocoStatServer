function Get-ChocoStatPackage {
    <#
    .SYNOPSIS
        Lists packages in the database depending on the filters
    .DESCRIPTION
        The packages can be filtered by one or more PackageNames which might contain SQL-Wildcards
    .NOTES
        The SQL-Table 'Packages' currently only consists of the "PackageName"-Column, so there is no more details than the name itself. This Cmdlet can therefore only be used to determine if the package is already existing in the database.
    .EXAMPLE
        Get-ChocoStatPackage
        
        Lists all packages in the database
    .EXAMPLE
        Get-ChocoStatPackage -PackageName 'firefox'

        Lists the package 'firefox'
    .EXAMPLE
        Get-ChocoStatPackage -PackageName '%.extension','notepad'

        Lists all packages which ends with '.extension' or the name 'notepad'
    #>
    
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        # One or more PackageNames to search for (can contain SQL wildcards)
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 0
        )]
        [String[]]
        $PackageName=@('%')
    )

    process {

        $Query = "SELECT * FROM Packages WHERE"

        $Query += ($PackageName | ForEach-Object { " PackageName LIKE '$_'" } ) -join ' OR '

        $Query += ";"

        Write-Verbose "Get-ChocoStatPackage: Execute SQL Query: $Query"

        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            PackageName = $PackageName
        }
    }    
}
