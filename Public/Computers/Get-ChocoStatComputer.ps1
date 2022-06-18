function Get-ChocoStatComputer {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        [Parameter()]        
        [String]
        $ComputerName
    )

    process {
        if ($ComputerName) {
            $Query = "SELECT * FROM Computers WHERE ComputerName=@ComputerName;"
        } else {
            $Query = "SELECT * FROM Computers;"
        }
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
        }
    }
    
}