function New-ChocoStatPackage {
    [CmdletBinding()]
    [OutputType([Object])]

    param (
        [Parameter(Mandatory)]        
        [String]
        $PackageName
    )

    process {

        $Packages = Get-ChocoStatPackage

        if ($Packages.PackageName -notcontains $PackageName) {
            $Query = "INSERT INTO Packages (PackageName) VALUES (@PackageName)"
            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                PackageName = $PackageName
            }
        }
        
    }
    
}