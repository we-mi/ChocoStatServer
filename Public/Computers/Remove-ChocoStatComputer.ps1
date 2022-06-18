function Remove-ChocoStatComputer {
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $ComputerName
    )

    process {

        $Query = "DELETE FROM Computers WHERE ComputerName=@ComputerName"
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
        }
        
    }
    
}