function Add-ChocoStatComputerPackage {
    [CmdletBinding()]
    [OutputType([Object[]])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $ComputerName,

        [Parameter(Mandatory)]        
        [String]
        $PackageName,

        [Parameter(Mandatory)]
        [String]
        $Version,

        [Parameter()]
        [String]
        $Parameters,

        [Parameter()]
        [datetime]
        $InstalledOn
    )

    process {
        
        $Query = "INSERT INTO Computers_Packages (ComputerName, PackageName, Version, Parameters, InstalledOn) VALUES (@ComputerName, @PackageName, @Version, @Parameters, @InstalledOn)"


        Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
            ComputerName = $ComputerName
            PackageName = $PackageName
            Version = $Version
            Parameters = $Parameters
            InstalledOn = $InstalledOn
        }
    }
    
}