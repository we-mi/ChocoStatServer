function Remove-ChocoStatPackage {
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $PackageName
    )

    process {

        $Query = "DELETE FROM Packages WHERE PackageName=@PackageName"
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            PackageName = $PackageName
        }
        
    }
    
}