function Update-ChocoStatComputerPackage {
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

        $ComputerPackageObject = Get-ChocoStatComputerPackage -ComputerName $ComputerName | Where-Object { $_.PackageName -eq $PackageName }

        if ($ComputerPackageObject) {

            if ([String]::IsNullOrWhiteSpace($Version) -and [String]::IsNullOrWhiteSpace($Parameters) -and $null -eq $InstalledOn) {
                return $null
            }

            if ([String]::IsNullOrWhiteSpace($Version)) {
                $Version = $ComputerPackageObject.Version
            }

            if ([String]::IsNullOrWhiteSpace($Parameters)) {
                $Parameters = $ComputerPackageObject.Parameters
            }

            if ($null -eq $InstalledOn) {
                if ($null -eq $ComputerPackageObject.InstalledOn) {
                    $InstalledOn = [datetime]"1970-01-01"
                } else {
                    $InstalledOn = $ComputerPackageObject.InstalledOn
                }
            }
        
            $Query = "UPDATE Computers_Packages SET Version=@Version, Parameters=@Parameters, InstalledOn=@InstalledOn WHERE ComputerID=@ComputerID AND PackageName=@PackageName"

            Invoke-SqliteQuery -Query $Query -Database $script:File -SqlParameters @{
                ComputerID = $ComputerPackageObject.ComputerID
                PackageName = $PackageName
                Version = $Version
                Parameters = $Parameters
                InstalledOn = $InstalledOn
            }
        } else {
            $splat = @{
                ComputerName = $ComputerName
                PackageName = $PackageName
                Version = $Version
            }

            if (-not [String]::IsNullOrWhiteSpace($Parameters)) {
                $splat.Parameters = $Parameters
            }

            if ($null -ne $InstalledOn) {
                $splat.InstalledOn = $InstalledOn
            }

            Add-ChocoStatComputerPackage @splat
        }
    
    }
    
}