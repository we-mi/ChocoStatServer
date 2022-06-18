function Get-ChocoStatPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        [Parameter()]        
        [String]
        $PackageName
    )

    process {
        if ($PackageName) {
            $Query = "SELECT * FROM Packages WHERE PackageName=@PackageName;"
        } else {
            $Query = "SELECT * FROM Packages;"
        }
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            PackageName = $PackageName
        }
    }
    
}