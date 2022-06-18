function Get-ChocoStatComputerPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        [Parameter()]        
        [String]
        $ComputerName
    )

    process {
        if ($ComputerName) {
            $Query = "SELECT Computers.ComputerName,PackageName,Version,Parameters,InstalledOn FROM Computers_Packages,Computers WHERE Computers_Packages.ComputerName=Computers.ComputerName AND Computers.ComputerName=@ComputerName;"
        } else {
            $Query = "SELECT Computers.ComputerName,PackageName,Version,Parameters,InstalledOn FROM Computers_Packages,Computers WHERE Computers_Packages.ComputerName=Computers.ComputerName;"
        }
        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
        }
    }
    
}