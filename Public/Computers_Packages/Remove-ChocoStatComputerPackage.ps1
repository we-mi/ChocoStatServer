function Remove-ChocoStatComputerPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $ComputerName,

        [Parameter(Mandatory)]        
        [String]
        $PackageName,

        [Parameter()]
        [Switch]
        $Force
    )

    process {
        
        $Query = "DELETE FROM Computers_Packages WHERE ComputerName=@ComputerName AND PackageName=@PackageName"


        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
            PackageName = $PackageName
        }
    }
    
}